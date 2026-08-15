from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any


def helium_user_data_dir() -> Path:
    override = os.environ.get("HELIUM_USER_DATA_DIR")
    if override:
        return Path(override)
    xdg = os.environ.get("XDG_CONFIG_HOME")
    base = Path(xdg) if xdg else Path.home() / ".config"
    for name in ("net.imput.helium", "helium"):
        candidate = base / name
        if candidate.is_dir():
            return candidate
    return base / "net.imput.helium"


def inspect_enabled() -> bool:
    """True when helium://inspect/#remote-debugging wrote DevToolsActivePort."""
    return (helium_user_data_dir() / "DevToolsActivePort").is_file()


def remote_debugging_pref_enabled(user_data_dir: Path | None = None) -> bool:
    root = Path(user_data_dir) if user_data_dir is not None else helium_user_data_dir()
    path = root / "Local State"
    if not path.is_file():
        return False
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    if not isinstance(data, dict):
        return False
    devtools = data.get("devtools")
    if not isinstance(devtools, dict):
        return False
    remote = devtools.get("remote_debugging")
    if not isinstance(remote, dict):
        return False
    return remote.get("user-enabled") is True


def helium_is_running(user_data_dir: Path) -> bool:
    # Chromium writes SingletonLock as a dangling symlink (hostname-pid).
    # Path.exists() follows the target and would report "not running".
    lock = user_data_dir / "SingletonLock"
    return lock.is_symlink() or lock.exists()


def seed_remote_debugging(
    user_data_dir: Path | None = None, *, force: bool = False
) -> dict[str, Any]:
    """Persist helium://inspect remote debugging in Local State.

    Chromium 136+ (Helium 0.15 / Chromium 151 included) ignores
    --remote-debugging-port on the default user-data-dir and *errors out of
    GetInstance entirely* if that flag is present. The only persist path that
    still starts the loopback CDP server on the daily profile is
    Local State ``devtools.remote_debugging.user-enabled = true``.

    Do not write while Helium holds SingletonLock unless ``force`` is set:
    Helium owns Local State in memory and will overwrite a racing write.
    """
    root = Path(user_data_dir) if user_data_dir is not None else helium_user_data_dir()
    root.mkdir(parents=True, exist_ok=True)
    path = root / "Local State"
    if not force and helium_is_running(root):
        return {"status": "skipped_running", "path": str(path)}

    data: Any = {}
    if path.exists():
        raw = path.read_text(encoding="utf-8")
        if raw.strip():
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                return {"status": "skipped_corrupt", "path": str(path)}
    if not isinstance(data, dict):
        return {"status": "skipped_corrupt", "path": str(path)}

    devtools = data.get("devtools")
    if not isinstance(devtools, dict):
        devtools = {}
    remote = devtools.get("remote_debugging")
    if not isinstance(remote, dict):
        remote = {}
    if remote.get("user-enabled") is True:
        return {"status": "already_set", "path": str(path)}

    remote["user-enabled"] = True
    devtools["remote_debugging"] = remote
    data["devtools"] = devtools

    tmp = path.with_name("Local State.tmp")
    tmp.write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
    tmp.replace(path)
    return {"status": "written", "path": str(path)}


def main_seed(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Seed Helium Local State so remote debugging starts on launch."
    )
    parser.add_argument("--user-data-dir", type=Path, default=None)
    parser.add_argument(
        "--force",
        action="store_true",
        help="Write even if Helium is running (may be overwritten until restart).",
    )
    args = parser.parse_args(argv)
    result = seed_remote_debugging(args.user_data_dir, force=args.force)
    print(f"{result['status']} {result['path']}")
    return 0


if __name__ == "__main__":
    sys.exit(main_seed())

