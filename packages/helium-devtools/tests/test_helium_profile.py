import json
from pathlib import Path

from helium_devtools.helium_profile import (
    remote_debugging_pref_enabled,
    seed_remote_debugging,
)


def _local_state(dir: Path) -> Path:
    return dir / "Local State"


def test_seed_creates_local_state_when_missing(tmp_path: Path):
    result = seed_remote_debugging(tmp_path)
    assert result["status"] == "written"
    data = json.loads(_local_state(tmp_path).read_text())
    assert data["devtools"]["remote_debugging"]["user-enabled"] is True


def test_seed_merges_without_clobbering_other_keys(tmp_path: Path):
    _local_state(tmp_path).write_text(
        json.dumps({"browser": {"enabled_labs_experiments": ["x"]}, "devtools": {}})
    )
    result = seed_remote_debugging(tmp_path)
    assert result["status"] == "written"
    data = json.loads(_local_state(tmp_path).read_text())
    assert data["browser"]["enabled_labs_experiments"] == ["x"]
    assert data["devtools"]["remote_debugging"]["user-enabled"] is True


def test_seed_flips_false_to_true(tmp_path: Path):
    _local_state(tmp_path).write_text(
        json.dumps({"devtools": {"remote_debugging": {"user-enabled": False}}})
    )
    result = seed_remote_debugging(tmp_path)
    assert result["status"] == "written"
    data = json.loads(_local_state(tmp_path).read_text())
    assert data["devtools"]["remote_debugging"]["user-enabled"] is True


def test_seed_already_true_is_noop(tmp_path: Path):
    payload = {"devtools": {"remote_debugging": {"user-enabled": True}}, "keep": 1}
    _local_state(tmp_path).write_text(json.dumps(payload))
    before = _local_state(tmp_path).read_text()
    result = seed_remote_debugging(tmp_path)
    assert result["status"] == "already_set"
    assert _local_state(tmp_path).read_text() == before


def test_seed_skips_when_singleton_lock_exists(tmp_path: Path):
    (tmp_path / "SingletonLock").symlink_to("host-123")
    result = seed_remote_debugging(tmp_path)
    assert result["status"] == "skipped_running"
    assert not _local_state(tmp_path).exists()


def test_seed_force_writes_even_when_lock_exists(tmp_path: Path):
    (tmp_path / "SingletonLock").symlink_to("host-123")
    result = seed_remote_debugging(tmp_path, force=True)
    assert result["status"] == "written"
    data = json.loads(_local_state(tmp_path).read_text())
    assert data["devtools"]["remote_debugging"]["user-enabled"] is True


def test_seed_skips_corrupt_json(tmp_path: Path):
    path = _local_state(tmp_path)
    path.write_text("{not-json")
    result = seed_remote_debugging(tmp_path)
    assert result["status"] == "skipped_corrupt"
    assert path.read_text() == "{not-json"


def test_remote_debugging_pref_enabled_reads_local_state(tmp_path: Path):
    assert remote_debugging_pref_enabled(tmp_path) is False
    seed_remote_debugging(tmp_path)
    assert remote_debugging_pref_enabled(tmp_path) is True
