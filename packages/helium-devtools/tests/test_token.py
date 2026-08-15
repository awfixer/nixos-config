from pathlib import Path

import pytest

from helium_devtools.config import Config
from helium_devtools.errors import HELIUM_DISCONNECTED, HeliumDisconnectedError
from helium_devtools.mcp_agg import child_argv
from helium_devtools.token import read_token


def test_helium_disconnected_copy():
    assert HELIUM_DISCONNECTED == (
        "Helium not connected; open Helium and wait for the Grok DevTools extension to attach.\n"
        "If Helium is already open, restart it so --load-extension picks up ~/.local/share/helium-devtools/extension."
    )
    assert str(HeliumDisconnectedError()) == HELIUM_DISCONNECTED


def test_read_token_accepts_64_hex(tmp_path: Path):
    p = tmp_path / "token"
    p.write_text("ab" * 32)
    assert read_token(p) == "ab" * 32


def test_read_token_rejects_short(tmp_path: Path):
    p = tmp_path / "token"
    p.write_text("abc")
    with pytest.raises(ValueError):
        read_token(p)


def test_config_from_env_reads_ports_and_token(tmp_path: Path):
    token = "cd" * 32
    p = tmp_path / "token"
    p.write_text(token)
    cfg = Config.from_env(
        {
            "HELIUM_DEVTOOLS_TOKEN_FILE": str(p),
            "HELIUM_DEVTOOLS_EXT_PORT": "17320",
            "HELIUM_DEVTOOLS_MCP_PORT": "17321",
            "HELIUM_DEVTOOLS_CDP_PORT": "9222",
            "HELIUM_DEVTOOLS_CDP_MCP": "/nix/store/fake/bin/chrome-devtools-mcp",
        }
    )
    assert cfg.token == token
    assert cfg.bind == "127.0.0.1"
    assert cfg.ext_port == 17320
    assert cfg.mcp_port == 17321
    assert cfg.cdp_port == 9222
    assert cfg.cdp_mcp.endswith("chrome-devtools-mcp")


def test_child_argv_uses_shim_browser_url():
    cmd, args = child_argv("/bin/fake-mcp", "http://127.0.0.1:9222")
    assert cmd == "/bin/fake-mcp"
    assert args == [
        "--browser-url",
        "http://127.0.0.1:9222",
        "--no-usage-statistics",
    ]
    assert "--autoConnect" not in args
    assert "--executable-path" not in args
    assert "--user-data-dir" not in args
