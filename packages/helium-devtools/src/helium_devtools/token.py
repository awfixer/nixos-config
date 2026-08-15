from __future__ import annotations

import re
from pathlib import Path

_TOKEN_RE = re.compile(r"^[0-9a-f]{64}$")


def read_token(path: Path) -> str:
    text = path.read_text().strip()
    if not _TOKEN_RE.fullmatch(text):
        raise ValueError(f"token file {path} is not 64 lowercase hex chars")
    return text
