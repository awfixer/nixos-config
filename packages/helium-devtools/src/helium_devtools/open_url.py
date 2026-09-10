"""Open http(s) URLs in the running Helium via the helium-devtools CDP shim.

Grok Build uses the webbrowser crate, which tries $BROWSER first, then the
XDG default. A second `helium <url>` process often fails to hand the URL to
the already-open window because the wrapper injects --load-extension flags.
PUT /json/new on the loopback shim creates the tab through the extension.
"""

from __future__ import annotations

import argparse
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Sequence

DEFAULT_CDP_BASE = "http://127.0.0.1:9222"
URL_PREFIXES = ("http://", "https://")


def cdp_base(explicit: str | None = None, environ: dict[str, str] | None = None) -> str:
    env = os.environ if environ is None else environ
    if explicit:
        return explicit.rstrip("/")
    if env.get("HELIUM_OPEN_CDP_BASE"):
        return env["HELIUM_OPEN_CDP_BASE"].rstrip("/")
    host = env.get("HELIUM_DEVTOOLS_BIND", "127.0.0.1")
    port = env.get("HELIUM_DEVTOOLS_CDP_PORT", "9222")
    return f"http://{host}:{port}"


def iter_urls(args: Sequence[str]) -> list[str]:
    urls: list[str] = []
    skip_value = False
    for raw in args:
        if skip_value:
            skip_value = False
            continue
        if raw == "--":
            continue
        if raw in {"--if-running", "--help", "-h"}:
            continue
        if raw == "--cdp-base":
            skip_value = True
            continue
        if raw.startswith("--cdp-base="):
            continue
        if raw.startswith("-"):
            continue
        if raw.startswith(URL_PREFIXES):
            urls.append(raw)
    return urls


def open_via_cdp(url: str, base: str, timeout: float = 2.0) -> bool:
    quoted = urllib.parse.quote(url, safe="")
    target = f"{base}/json/new?url={quoted}"
    for method in ("PUT", "GET"):
        req = urllib.request.Request(target, method=method)
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                if 200 <= getattr(resp, "status", 200) < 300:
                    return True
        except urllib.error.HTTPError:
            continue
        except (urllib.error.URLError, TimeoutError, OSError):
            return False
    return False


def open_urls(urls: Sequence[str], base: str, timeout: float = 2.0) -> bool:
    if not urls:
        return False
    return all(open_via_cdp(url, base, timeout=timeout) for url in urls)


def fallback_exec(urls: Sequence[str], environ: dict[str, str] | None = None) -> None:
    env = os.environ if environ is None else environ
    helium = env.get("HELIUM_BIN", "helium")
    os.execvp(helium, [helium, *urls])


def run(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="helium-open",
        description="Open http(s) URLs as tabs in the already-running Helium.",
    )
    parser.add_argument(
        "--if-running",
        action="store_true",
        help="Succeed only via CDP; do not exec helium. For the helium wrapper.",
    )
    parser.add_argument("--cdp-base", default=None, help="CDP HTTP origin (default loopback :9222).")
    parser.add_argument("args", nargs=argparse.REMAINDER)
    opts = parser.parse_args(list(argv) if argv is not None else None)
    urls = iter_urls(opts.args)
    base = cdp_base(opts.cdp_base)
    if urls and open_urls(urls, base):
        return 0
    if opts.if_running:
        return 1
    try:
        fallback_exec(urls)
    except FileNotFoundError:
        return 1
    return 1


def _log_invocation(argv: Sequence[str] | None) -> None:
    try:
        state = os.environ.get("XDG_STATE_HOME") or os.path.join(os.path.expanduser("~"), ".local/state")
        path = os.path.join(state, "helium-open.log")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        args = list(argv) if argv is not None else sys.argv[1:]
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(f"{os.getpid()} argv={args!r}\n")
    except OSError:
        pass


def main() -> None:
    _log_invocation(None)
    raise SystemExit(run())
