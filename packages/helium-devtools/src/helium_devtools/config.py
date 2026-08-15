from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

from helium_devtools.token import read_token


@dataclass(frozen=True)
class Config:
    token: str
    token_file: Path
    bind: str = "127.0.0.1"
    ext_port: int = 17320
    mcp_port: int = 17321
    cdp_port: int = 9222
    cdp_mcp: str | None = None

    @classmethod
    def from_env(cls, environ: Mapping[str, str] | None = None) -> Config:
        env = environ if environ is not None else os.environ
        token_file = Path(env["HELIUM_DEVTOOLS_TOKEN_FILE"])
        return cls(
            token=read_token(token_file),
            token_file=token_file,
            bind="127.0.0.1",
            ext_port=int(env.get("HELIUM_DEVTOOLS_EXT_PORT", "17320")),
            mcp_port=int(env.get("HELIUM_DEVTOOLS_MCP_PORT", "17321")),
            cdp_port=int(env.get("HELIUM_DEVTOOLS_CDP_PORT", "9222")),
            cdp_mcp=env.get("HELIUM_DEVTOOLS_CDP_MCP") or None,
        )
