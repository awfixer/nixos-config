/*
 * macbook-thermal — MacBook9,1 (m3-6Y30) keep-alive
 *
 * applesmc on 6.18 logs `fan=0` because SMC key FNum is 0, so it never
 * creates fan*_input / fan*_output. The 12" chassis still has a fan
 * (F0Ac/F0Tg). Meanwhile intel_rapl advertises PL1/PL2 = 49 W on a 4.5 W
 * part. Result: idle thermal shutdown in ~20 minutes.
 *
 * This daemon:
 *   1. Caps package RAPL well below the 49 W firmware lie, with
 *      enough headroom that the m3 is usable (not pinned at TDP).
 *   2. Prefers applesmc sysfs if fan1_output exists (patched driver).
 *   3. Otherwise rmmod is expected (NixOS blacklists applesmc) and we
 *      talk to the SMC at 0x300/0x304 the same way applesmc.c does.
 */

#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>

#include <dirent.h>
#include <sys/io.h>
#include <sys/types.h>

#define APPLESMC_DATA_PORT 0x300
#define APPLESMC_CMD_PORT  0x304
#define APPLESMC_NR_PORTS  32

#define SMC_STATUS_AWAITING_DATA BIT(0)
#define SMC_STATUS_IB_CLOSED     BIT(1)
#define SMC_STATUS_BUSY          BIT(2)
#define BIT(n) (1u << (n))

#define APPLESMC_MIN_WAIT 0x0008
#define APPLESMC_READ_CMD  0x10
#define APPLESMC_WRITE_CMD 0x11
#define APPLESMC_GET_KEY_BY_INDEX_CMD 0x12
#define APPLESMC_GET_KEY_TYPE_CMD     0x13

/* Firmware advertised 49 W and the chassis cooked. Datasheet TDP is 4.5 W
 * / cTDP-up 7 W; pinning there plus EPP=power left the cores at ~600 MHz
 * under load at only ~60 C. 15/22 W is still far under 49 W. Turbo and
 * EPP drop if the package actually gets hot. */
#define PL1_UW 15000000 /* sustained cap */
#define PL2_UW 22000000 /* short burst */
#define PL2_WINDOW_US 10000000 /* 10 s turbo window */
#define EPP_COOL "balance_performance"
#define EPP_HOT "power"

#define TEMP_MIN_C 50
#define TEMP_MAX_C 72
#define DEFAULT_MIN_RPM 2000
#define DEFAULT_MAX_RPM 6200
#define POLL_MS 1000

static volatile sig_atomic_t g_stop;
static bool g_smc_ok;
static bool g_sysfs_fan;
static bool g_fan_usable;
static bool g_saw_f0tg;
static uint8_t g_fnum;
static char g_fan_output[128];
static char g_fan_manual[128];
static char g_fan_min[128];
static char g_fan_max[128];
static char g_coretemp_input[512];

static void die_log(int pri, const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	vsyslog(pri, fmt, ap);
	va_end(ap);
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	fputc('\n', stderr);
	va_end(ap);
}

static void on_signal(int sig)
{
	(void)sig;
	g_stop = 1;
}

static void msleep(unsigned int ms)
{
	struct timespec ts = {
		.tv_sec = ms / 1000,
		.tv_nsec = (long)(ms % 1000) * 1000000L,
	};
	while (nanosleep(&ts, &ts) == -1 && errno == EINTR)
		;
}

static int write_sysfs(const char *path, const char *value)
{
	int fd = open(path, O_WRONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	size_t n = strlen(value);
	ssize_t w = write(fd, value, n);
	int err = (w < 0) ? -errno : 0;
	close(fd);
	if (w >= 0 && (size_t)w != n)
		return -EIO;
	return err;
}

static int read_sysfs_long(const char *path, long *out)
{
	char buf[64];
	int fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	ssize_t n = read(fd, buf, sizeof(buf) - 1);
	close(fd);
	if (n <= 0)
		return n < 0 ? -errno : -EIO;
	buf[n] = '\0';
	char *end = NULL;
	long v = strtol(buf, &end, 10);
	if (end == buf)
		return -EINVAL;
	*out = v;
	return 0;
}

/* ---- RAPL / intel_pstate ---------------------------------------------- */

static void apply_rapl(void)
{
	static const char *const pl1 =
		"/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw";
	static const char *const pl1max =
		"/sys/class/powercap/intel-rapl:0/constraint_0_max_power_uw";
	static const char *const pl2 =
		"/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw";
	static const char *const pl2max =
		"/sys/class/powercap/intel-rapl:0/constraint_1_max_power_uw";
	static const char *const pl2w =
		"/sys/class/powercap/intel-rapl:0/constraint_1_time_window_us";
	static const char *const en =
		"/sys/class/powercap/intel-rapl:0/enabled";

	char buf[32];
	int r;

	r = write_sysfs(en, "1");
	if (r)
		die_log(LOG_WARNING, "rapl enabled: %s", strerror(-r));

	/* Some RAPL sysfs trees refuse a limit above max (this SKU's
	 * long_term max starts at 4.5 W). Raise max first; ignore EROFS. */
	snprintf(buf, sizeof(buf), "%d", PL1_UW);
	r = write_sysfs(pl1max, buf);
	if (r)
		die_log(LOG_WARNING, "PL1 max write: %s", strerror(-r));
	r = write_sysfs(pl1, buf);
	if (r)
		die_log(LOG_ERR, "PL1 %s: %s", pl1, strerror(-r));

	snprintf(buf, sizeof(buf), "%d", PL2_UW);
	r = write_sysfs(pl2max, buf);
	if (r)
		die_log(LOG_WARNING, "PL2 max write: %s", strerror(-r));
	r = write_sysfs(pl2, buf);
	if (r)
		die_log(LOG_WARNING, "PL2 write: %s", strerror(-r));

	snprintf(buf, sizeof(buf), "%d", PL2_WINDOW_US);
	r = write_sysfs(pl2w, buf);
	if (r)
		die_log(LOG_WARNING, "PL2 window write: %s", strerror(-r));
}

static void apply_no_turbo(int on)
{
	int r = write_sysfs("/sys/devices/system/cpu/intel_pstate/no_turbo",
			    on ? "1" : "0");
	if (r)
		die_log(LOG_WARNING, "no_turbo=%d: %s", on, strerror(-r));
}

static void apply_epp(const char *pref)
{
	DIR *d = opendir("/sys/devices/system/cpu");
	if (!d)
		return;
	struct dirent *de;
	while ((de = readdir(d))) {
		if (strncmp(de->d_name, "cpu", 3) != 0)
			continue;
		if (de->d_name[3] < '0' || de->d_name[3] > '9')
			continue;
		char path[512];
		if (snprintf(path, sizeof(path),
			     "/sys/devices/system/cpu/%s/cpufreq/energy_performance_preference",
			     de->d_name) >= (int)sizeof(path))
			continue;
		write_sysfs(path, pref);
	}
	closedir(d);
}

/* ---- coretemp ---------------------------------------------------------- */

static int find_coretemp(void)
{
	DIR *d = opendir("/sys/class/hwmon");
	if (!d)
		return -errno;
	struct dirent *de;
	int found = 0;
	while ((de = readdir(d))) {
		if (de->d_name[0] == '.')
			continue;
		char namep[512], name[64];
		if (snprintf(namep, sizeof(namep), "/sys/class/hwmon/%s/name", de->d_name) >=
		    (int)sizeof(namep))
			continue;
		int fd = open(namep, O_RDONLY | O_CLOEXEC);
		if (fd < 0)
			continue;
		ssize_t n = read(fd, name, sizeof(name) - 1);
		close(fd);
		if (n <= 0)
			continue;
		name[n] = '\0';
		if (strncmp(name, "coretemp", 8) != 0)
			continue;
		if (snprintf(g_coretemp_input, sizeof(g_coretemp_input),
			     "/sys/class/hwmon/%s/temp1_input", de->d_name) >=
		    (int)sizeof(g_coretemp_input))
			continue;
		found = 1;
		break;
	}
	closedir(d);
	return found ? 0 : -ENOENT;
}

static int package_temp_c(void)
{
	long mdeg = 0;
	if (!g_coretemp_input[0] && find_coretemp() != 0)
		return -1;
	if (read_sysfs_long(g_coretemp_input, &mdeg) != 0)
		return -1;
	return (int)(mdeg / 1000);
}

/* ---- applesmc sysfs fan (if a patched driver created it) -------------- */

static bool find_sysfs_fan(void)
{
	static const char *roots[] = {
		"/sys/devices/platform/applesmc.768",
		NULL,
	};
	for (int i = 0; roots[i]; i++) {
		char path[192];
		snprintf(path, sizeof(path), "%s/fan1_output", roots[i]);
		if (access(path, W_OK) != 0)
			continue;
		snprintf(g_fan_output, sizeof(g_fan_output), "%s/fan1_output", roots[i]);
		snprintf(g_fan_manual, sizeof(g_fan_manual), "%s/fan1_manual", roots[i]);
		snprintf(g_fan_min, sizeof(g_fan_min), "%s/fan1_min", roots[i]);
		snprintf(g_fan_max, sizeof(g_fan_max), "%s/fan1_max", roots[i]);
		return true;
	}
	return false;
}

/* ---- SMC I/O (copy of applesmc.c protocol, userspace) ----------------- */

static int wait_status(uint8_t val, uint8_t mask)
{
	int us = APPLESMC_MIN_WAIT;
	for (int i = 0; i < 24; i++) {
		uint8_t status = inb(APPLESMC_CMD_PORT);
		if ((status & mask) == val)
			return 0;
		usleep((useconds_t)us);
		if (i > 9)
			us <<= 1;
	}
	return -EIO;
}

static int send_byte(uint8_t cmd, uint16_t port)
{
	int status = wait_status(0, SMC_STATUS_IB_CLOSED);
	if (status)
		return status;
	status = wait_status(SMC_STATUS_BUSY, SMC_STATUS_BUSY);
	if (status)
		return status;
	outb(cmd, port);
	return 0;
}

static int send_command(uint8_t cmd)
{
	int ret = wait_status(0, SMC_STATUS_IB_CLOSED);
	if (ret)
		return ret;
	outb(cmd, APPLESMC_CMD_PORT);
	return 0;
}

static int smc_sane(void)
{
	int ret = wait_status(0, SMC_STATUS_BUSY);
	if (!ret)
		return ret;
	ret = send_command(APPLESMC_READ_CMD);
	if (ret)
		return ret;
	return wait_status(0, SMC_STATUS_BUSY);
}

static int send_argument(const char *key)
{
	for (int i = 0; i < 4; i++)
		if (send_byte((uint8_t)key[i], APPLESMC_DATA_PORT))
			return -EIO;
	return 0;
}

static int read_smc_cmd(uint8_t cmd, const char *key, uint8_t *buffer, uint8_t len)
{
	int ret = smc_sane();
	if (ret)
		return ret;
	if (send_command(cmd) || send_argument(key))
		return -EIO;
	if (send_byte(len, APPLESMC_DATA_PORT))
		return -EIO;
	for (int i = 0; i < len; i++) {
		if (wait_status(SMC_STATUS_AWAITING_DATA | SMC_STATUS_BUSY,
				SMC_STATUS_AWAITING_DATA | SMC_STATUS_BUSY))
			return -EIO;
		buffer[i] = inb(APPLESMC_DATA_PORT);
	}
	for (int i = 0; i < 16; i++) {
		usleep(APPLESMC_MIN_WAIT);
		uint8_t status = inb(APPLESMC_CMD_PORT);
		if (!(status & SMC_STATUS_AWAITING_DATA))
			break;
		(void)inb(APPLESMC_DATA_PORT);
	}
	return wait_status(0, SMC_STATUS_BUSY);
}

static int read_smc(const char *key, uint8_t *buffer, uint8_t len)
{
	return read_smc_cmd(APPLESMC_READ_CMD, key, buffer, len);
}

/* GET_KEY_TYPE: 6 bytes = len, type[4], flags */
static int smc_key_info(const char *key, uint8_t *len, char type[5], uint8_t *flags)
{
	uint8_t info[6];
	int ret = read_smc_cmd(APPLESMC_GET_KEY_TYPE_CMD, key, info, 6);
	if (ret)
		return ret;
	if (len)
		*len = info[0];
	if (type) {
		memcpy(type, &info[1], 4);
		type[4] = '\0';
	}
	if (flags)
		*flags = info[5];
	return 0;
}

static int write_smc(const char *key, const uint8_t *buffer, uint8_t len)
{
	int ret = smc_sane();
	if (ret)
		return ret;
	if (send_command(APPLESMC_WRITE_CMD) || send_argument(key))
		return -EIO;
	if (send_byte(len, APPLESMC_DATA_PORT))
		return -EIO;
	for (int i = 0; i < len; i++) {
		if (send_byte(buffer[i], APPLESMC_DATA_PORT))
			return -EIO;
	}
	return wait_status(0, SMC_STATUS_BUSY);
}

static int smc_read_fpe2(const char *key, unsigned int *rpm)
{
	uint8_t b[2];
	int ret = read_smc(key, b, 2);
	if (ret)
		return ret;
	*rpm = ((unsigned int)b[0] << 8 | b[1]) >> 2;
	return 0;
}

static int smc_write_fpe2(const char *key, unsigned int rpm)
{
	uint8_t b[2];
	if (rpm >= 0x4000)
		rpm = 0x3fff;
	b[0] = (uint8_t)((rpm >> 6) & 0xff);
	b[1] = (uint8_t)((rpm << 2) & 0xff);
	return write_smc(key, b, 2);
}

static int smc_set_manual(int on)
{
	uint8_t b[2];
	int ret = read_smc("FS! ", b, 2);
	if (ret)
		return ret;
	unsigned int val = ((unsigned int)b[0] << 8) | b[1];
	if (on)
		val |= 0x1;
	else
		val &= ~0x1u;
	b[0] = (uint8_t)((val >> 8) & 0xff);
	b[1] = (uint8_t)(val & 0xff);
	return write_smc("FS! ", b, 2);
}

static void hexdump_key(const char *key, const uint8_t *b, uint8_t n)
{
	char hex[96];
	size_t off = 0;
	for (uint8_t i = 0; i < n && off + 3 < sizeof(hex); i++)
		off += (size_t)snprintf(hex + off, sizeof(hex) - off, "%02x", b[i]);
	die_log(LOG_INFO, "SMC %s = %s", key, hex);
}

static void probe_one_key(const char *key)
{
	uint8_t len = 0, flags = 0, buf[32];
	char type[5] = { 0 };
	int ret = smc_key_info(key, &len, type, &flags);
	if (ret) {
		die_log(LOG_INFO, "SMC %s: no such key (%s)", key, strerror(-ret));
		return;
	}
	if (len > sizeof(buf))
		len = sizeof(buf);
	ret = read_smc(key, buf, len);
	if (ret) {
		die_log(LOG_INFO, "SMC %s type='%s' len=%u flags=0x%02x read-fail %s",
			key, type, len, flags, strerror(-ret));
		return;
	}
	die_log(LOG_INFO, "SMC %s type='%s' len=%u flags=0x%02x", key, type, len, flags);
	hexdump_key(key, buf, len);
	if (memcmp(key, "F0Tg", 4) == 0)
		g_saw_f0tg = true;
	if (memcmp(key, "FNum", 4) == 0 && len >= 1)
		g_fnum = buf[0];
}

static void dump_smc_f_keys(void)
{
	uint8_t be[4], name[4];
	uint32_t count = 0;
	int ret = read_smc("#KEY", be, 4);
	if (ret) {
		die_log(LOG_WARNING, "#KEY read failed: %s", strerror(-ret));
		return;
	}
	count = ((uint32_t)be[0] << 24) | ((uint32_t)be[1] << 16) |
		((uint32_t)be[2] << 8) | be[3];
	die_log(LOG_INFO, "SMC #KEY=%u — listing F* keys", count);
	if (count > 2048)
		count = 2048;
	unsigned found = 0;
	for (uint32_t i = 0; i < count; i++) {
		uint8_t idx[4] = {
			(uint8_t)(i >> 24), (uint8_t)(i >> 16),
			(uint8_t)(i >> 8), (uint8_t)i
		};
		ret = read_smc_cmd(APPLESMC_GET_KEY_BY_INDEX_CMD, (char *)idx, name, 4);
		if (ret)
			continue;
		if (name[0] != 'F')
			continue;
		char key[5] = { name[0], name[1], name[2], name[3], 0 };
		probe_one_key(key);
		found++;
	}
	die_log(LOG_INFO, "SMC F* keys found: %u", found);
}

static int rpm_for_temp(int c, int min_rpm, int max_rpm)
{
	if (c <= TEMP_MIN_C)
		return min_rpm;
	if (c >= TEMP_MAX_C)
		return max_rpm;
	return min_rpm + (max_rpm - min_rpm) * (c - TEMP_MIN_C) /
			     (TEMP_MAX_C - TEMP_MIN_C);
}

static int open_smc(void)
{
	if (ioperm(APPLESMC_DATA_PORT, APPLESMC_NR_PORTS, 1) != 0) {
		die_log(LOG_ERR, "ioperm 0x%x: %s", APPLESMC_DATA_PORT, strerror(errno));
		return -1;
	}
	g_smc_ok = true;
	return 0;
}

static void close_smc(void)
{
	if (!g_smc_ok)
		return;
	smc_set_manual(0);
	ioperm(APPLESMC_DATA_PORT, APPLESMC_NR_PORTS, 0);
	g_smc_ok = false;
}

/* ---- fan apply -------------------------------------------------------- */

static int set_fan_rpm(unsigned int rpm)
{
	char buf[16];

	if (g_sysfs_fan) {
		if (g_fan_manual[0])
			write_sysfs(g_fan_manual, "1");
		snprintf(buf, sizeof(buf), "%u\n", rpm);
		return write_sysfs(g_fan_output, buf);
	}
	if (!g_smc_ok || !g_fan_usable)
		return -ENODEV;
	int r = smc_set_manual(1);
	if (r)
		return r;
	return smc_write_fpe2("F0Tg", rpm);
}

static void restore_fan_auto(void)
{
	if (g_sysfs_fan && g_fan_manual[0])
		write_sysfs(g_fan_manual, "0");
	else if (g_smc_ok)
		smc_set_manual(0);
}

static void read_fan_limits(int *min_rpm, int *max_rpm)
{
	*min_rpm = DEFAULT_MIN_RPM;
	*max_rpm = DEFAULT_MAX_RPM;
	if (g_sysfs_fan) {
		long v;
		if (read_sysfs_long(g_fan_min, &v) == 0 && v > 0)
			*min_rpm = (int)v;
		if (read_sysfs_long(g_fan_max, &v) == 0 && v > *min_rpm)
			*max_rpm = (int)v;
		return;
	}
	if (!g_smc_ok)
		return;
	unsigned int v;
	if (smc_read_fpe2("F0Mn", &v) == 0 && v > 0)
		*min_rpm = (int)v;
	if (smc_read_fpe2("F0Mx", &v) == 0 && (int)v > *min_rpm)
		*max_rpm = (int)v;
}

int main(void)
{
	openlog("macbook-thermal", LOG_PID | LOG_PERROR, LOG_DAEMON);
	signal(SIGTERM, on_signal);
	signal(SIGINT, on_signal);

	if (find_coretemp() != 0)
		die_log(LOG_WARNING, "coretemp hwmon not found yet; will retry");

	apply_rapl();
	apply_no_turbo(0);
	apply_epp(EPP_COOL);

	g_sysfs_fan = find_sysfs_fan();
	if (g_sysfs_fan) {
		g_fan_usable = true;
		die_log(LOG_INFO, "using applesmc sysfs fan at %s", g_fan_output);
	} else {
		die_log(LOG_INFO, "no applesmc fan sysfs; probing SMC ports");
		if (open_smc() != 0)
			die_log(LOG_ERR, "SMC ioperm failed — RAPL cap only, fan uncontrolled");
		else {
			/* Only touch keys that exist: GET_KEY_TYPE on a missing
			 * name jams some SMCs. Walk the table for F*. */
			dump_smc_f_keys();
			if (g_saw_f0tg) {
				g_fan_usable = true;
				die_log(LOG_INFO, "F0Tg present — will drive fan");
			} else {
				die_log(LOG_ERR,
					"FNum=%u and no F0Tg — OS cannot command the fan; RAPL only",
					g_fnum);
			}
		}
	}

	int min_rpm, max_rpm;
	read_fan_limits(&min_rpm, &max_rpm);
	die_log(LOG_INFO, "fan curve %d–%d RPM over %d–%d C; RAPL PL1=%d mW PL2=%d mW",
		min_rpm, max_rpm, TEMP_MIN_C, TEMP_MAX_C, PL1_UW / 1000, PL2_UW / 1000);

	int last_logged = -100;
	int turbo_off = 0;
	int epp_hot = 0;
	while (!g_stop) {
		apply_rapl();

		int c = package_temp_c();
		if (c < 0) {
			find_coretemp();
			msleep(POLL_MS);
			continue;
		}

		/* TJMax on this SKU is 100 C. Clamp well below boil; without
		 * OS fan control, start backing off a little earlier. */
		int want_no_turbo = (c >= 85) || (!g_fan_usable && c >= 80);
		if (want_no_turbo != turbo_off) {
			apply_no_turbo(want_no_turbo);
			turbo_off = want_no_turbo;
		}
		if (want_no_turbo != epp_hot) {
			apply_epp(want_no_turbo ? EPP_HOT : EPP_COOL);
			epp_hot = want_no_turbo;
		}

		int rpm = rpm_for_temp(c, min_rpm, max_rpm);
		if (g_fan_usable) {
			int fr = set_fan_rpm((unsigned int)rpm);
			if (fr && abs(c - last_logged) >= 2)
				die_log(LOG_WARNING, "fan set %d rpm failed: %s", rpm,
					strerror(-fr));
		}

		if (abs(c - last_logged) >= 2) {
			unsigned int ac = 0;
			if (g_fan_usable && g_smc_ok)
				smc_read_fpe2("F0Ac", &ac);
			die_log(LOG_INFO, "pkg %d C%s%s", c,
				turbo_off ? " no_turbo" : "",
				g_fan_usable ? "" : " (no OS fan control)");
			(void)rpm;
			(void)ac;
			last_logged = c;
		}
		msleep(POLL_MS);
	}

	restore_fan_auto();
	close_smc();
	die_log(LOG_INFO, "stopped, fan returned to SMC auto");
	closelog();
	return 0;
}
