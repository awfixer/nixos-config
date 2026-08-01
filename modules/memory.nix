{ lib, ... }:

{
  # ---------------------------------------------------------------------------
  # Swap strategy for 8 GiB MacBook9,1 (m3-6Y30)
  #
  # Problem: rustc alone peaks ~5 GiB; with zero swap the kernel OOM-kills it
  # and systemd may tear down the whole ghostty scope (including the agent).
  #
  # Layout (do NOT enable boot.zswap — it conflicts with zramSwap):
  #   1. zram (priority 100) — compressed RAM, first choice, fast
  #   2. /var/lib/swapfile 8 GiB (priority 10) — NVMe overflow when zram full
  # ---------------------------------------------------------------------------

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    # Store up to 100% of RAM as compressed pages (typically holds ~2×+ logical).
    memoryPercent = 100;
    priority = 100;
  };

  # Auto-created on activation (size is MiB). 115 GiB free on root — safe.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024; # 8 GiB
      priority = 10;
    }
  ];

  # /tmp on disk, not RAM (tmpfs would compete with zram under builds).
  boot.tmp = {
    useTmpfs = false;
    cleanOnBoot = true;
  };

  boot.kernel.sysctl = {
    # zram-friendly: swap early to compressed RAM rather than thrashing late.
    "vm.swappiness" = 180;
    # Single-page swap I/O (zram is random-access; multi-page readahead hurts).
    "vm.page-cluster" = 0;
    # Reclaim a bit earlier so we slide into zram instead of hard OOM.
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.vfs_cache_pressure" = 50;
    # Keep a slightly larger free reserve for the allocator under pressure.
    "vm.min_free_kbytes" = 131072;
  };
}
