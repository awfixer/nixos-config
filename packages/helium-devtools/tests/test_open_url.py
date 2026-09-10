from __future__ import annotations

import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

from helium_devtools.open_url import cdp_base, iter_urls, open_urls, run


def test_iter_urls_skips_chromium_flags():
    args = [
        "--load-extension=/tmp/ext",
        "--disable-features=DisableLoadExtensionCommandLineSwitch",
        "https://mcp.example/oauth?x=1",
        "http://127.0.0.1:9/callback",
        "not-a-url",
    ]
    assert iter_urls(args) == [
        "https://mcp.example/oauth?x=1",
        "http://127.0.0.1:9/callback",
    ]


def test_iter_urls_ignores_shell_garbage_and_cdp_flags():
    assert iter_urls(
        [
            "--if-running",
            "--cdp-base",
            "http://127.0.0.1:9",
            "${NIXOS_OZONE_WL:+${WAYLAND_DISPLAY:+--ozone-platform-hint=auto",
            "https://accounts.x.ai/sign-in",
        ]
    ) == ["https://accounts.x.ai/sign-in"]


def test_cdp_base_from_env():
    assert cdp_base(environ={}) == "http://127.0.0.1:9222"
    assert (
        cdp_base(environ={"HELIUM_DEVTOOLS_BIND": "127.0.0.1", "HELIUM_DEVTOOLS_CDP_PORT": "9333"})
        == "http://127.0.0.1:9333"
    )
    assert cdp_base("http://127.0.0.1:1/", environ={"HELIUM_OPEN_CDP_BASE": "http://ignore"}) == (
        "http://127.0.0.1:1"
    )


class _CdpHandler(BaseHTTPRequestHandler):
    created: list[str] = []
    fail = False

    def log_message(self, format: str, *args: object) -> None:  # noqa: A003
        return

    def do_PUT(self) -> None:  # noqa: N802
        self._handle()

    def do_GET(self) -> None:  # noqa: N802
        self._handle()

    def _handle(self) -> None:
        if self.fail:
            self.send_error(503, "Helium not connected")
            return
        parsed = self.path.split("url=", 1)
        url = parsed[1] if len(parsed) == 2 else ""
        type(self).created.append(url)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"id":"tab-1"}')


def _serve(handler: type[BaseHTTPRequestHandler]) -> tuple[HTTPServer, str, threading.Thread]:
    httpd = HTTPServer(("127.0.0.1", 0), handler)
    host, port = httpd.server_address[:2]
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    return httpd, f"http://{host}:{port}", thread


def test_open_urls_put_json_new():
    _CdpHandler.created = []
    _CdpHandler.fail = False
    httpd, base, _thread = _serve(_CdpHandler)
    try:
        assert open_urls(["https://example.com/oauth"], base)
        assert any("https%3A%2F%2Fexample.com%2Foauth" in u for u in _CdpHandler.created)
    finally:
        httpd.shutdown()


def test_run_if_running_ok_and_fail():
    _CdpHandler.created = []
    _CdpHandler.fail = False
    httpd, base, _thread = _serve(_CdpHandler)
    try:
        assert (
            run(["--if-running", "--cdp-base", base, "https://mcp.sentry.dev/authorize"]) == 0
        )
        _CdpHandler.fail = True
        assert run(["--if-running", "--cdp-base", base, "https://mcp.sentry.dev/authorize"]) == 1
        assert run(["--if-running", "--cdp-base", base]) == 1
    finally:
        httpd.shutdown()
