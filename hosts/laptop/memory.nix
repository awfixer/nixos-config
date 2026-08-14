{ lib, ... }:

{
  # ---------------------------------------------------------------------------
  # Swap strategy for 8 GiB MacBook9,1 (m3-6Y30)
  #
  # Problem: rustc alone peaks ~5 GiB; with zero swap the kernel OOM-kills it
  # and systemd may tear down the whole ghostty scope (including the agent).
  #
  # Observed on this machine (zstd): ~3.7 GiB swapped → ~0.9 GiB compressed
  # (~4:1). That headroom is why we size zram larger than physical RAM.
  #
  # Layout (do NOT enable boot.zswap — it conflicts with zramSwap):
  #   1. zram (priority 100) — compressed RAM, first choice, fast
  #   2. /var/lib/swapfile 12 GiB (priority 10) — NVMe overflow when zram full
  # ---------------------------------------------------------------------------

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    # Logical capacity as % of RAM. 200% ≈ 15.4 GiB advertised on 7.7 GiB;
    # with ~3–4× compression the resident footprint stays well under RAM
    # until pathological incompressible load (then write pressure hits the
    # disk swapfile below).
    memoryPercent = 200;
    # Cap absolute size so a future RAM upgrade does not silently grow zram
    # past ~16 GiB logical without a conscious edit.
    memoryMax = 16 * 1024 * 1024 * 1024;
    priority = 100;
    swapDevices = 1;
  };

  # Auto-created on activation (size is MiB). Root has ~95 GiB free — safe.
  # Slightly larger than before so overflow after expanded zram still has room.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 12 * 1024; # 12 GiB
      priority = 10;
    }
  ];

  # /tmp on disk, not RAM (tmpfs would compete with zram under builds).
  boot.tmp = {
    useTmpfs = false;
    cleanOnBoot = true;
  };

  # Explicit: zswap + zram conflict; leave zswap off.
  boot.zswap.enable = false;

  # No automatic GC/optimise timers (background I/O + memory spikes under builds).
  nix.gc.automatic = false;
  nix.optimise.automatic = false;

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
