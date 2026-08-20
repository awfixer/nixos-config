#!/usr/bin/env python3
"""Unit tests for the bun plugin PreToolUse hook."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

import pretooluse as hook

POLICY = hook.load_policy()


def shell(command: str, tool="run_terminal_command") -> dict:
    return {"toolName": tool, "toolInput": {"command": command}}


def write(text: str, path="src/index.ts") -> dict:
    return {
        "toolName": "search_replace",
        "toolInput": {"file_path": path, "new_string": text},
    }


class ToolchainTests(unittest.TestCase):
    def assert_blocked(self, command: str, needle: str) -> None:
        reason = hook.decide(shell(command), POLICY)
        self.assertIsNotNone(reason, f"expected deny for: {command}")
        self.assertIn(needle, reason)

    def assert_allowed(self, command: str) -> None:
        reason = hook.decide(shell(command), POLICY)
        self.assertIsNone(reason, f"unexpected deny for {command!r}: {reason}")

    def test_npm_install(self):
        self.assert_blocked("npm install", "bun install")

    def test_npm_ci(self):
        self.assert_blocked("npm ci", "frozen-lockfile")

    def test_pnpm_add(self):
        self.assert_blocked("pnpm add react", "bun add")

    def test_yarn(self):
        self.assert_blocked("yarn", "Yarn")

    def test_npx(self):
        self.assert_blocked("npx eslint", "bunx")

    def test_node(self):
        self.assert_blocked("node src/index.ts", "`bun src/index.ts`")

    def test_tsx_and_nodemon(self):
        self.assert_blocked("tsx watch src/index.ts", "bun")
        self.assert_blocked("nodemon src/index.ts", "bun --watch")

    def test_chained_and_env(self):
        self.assert_blocked("cd apps/web && npm i", "bun install")
        self.assert_blocked("NODE_ENV=production npm install", "bun install")
        self.assert_blocked("sudo npm i", "bun install")
        self.assert_blocked("timeout 10 npm test", "bun test")

    def test_path_qualified(self):
        self.assert_blocked("/usr/bin/npm install", "bun install")
        self.assert_blocked("npm.cmd install", "bun install")

    def test_bun_allowed(self):
        self.assert_allowed("bun install")
        self.assert_allowed("bun add react")
        self.assert_allowed("bun test")
        self.assert_allowed("bun src/index.ts")
        self.assert_allowed("bunx eslint")
        self.assert_allowed("bun --watch src/index.ts")

    def test_unrelated_commands(self):
        self.assert_allowed("git status")
        self.assert_allowed("ls node_modules")
        self.assert_allowed("echo npm")
        self.assert_allowed("rm -rf node_modules")
        self.assert_allowed("nix-shell -p nodejs")

    def test_claude_bash_alias(self):
        reason = hook.decide(shell("npm install", tool="Bash"), POLICY)
        self.assertIsNotNone(reason)


class BuiltinPackageTests(unittest.TestCase):
    def test_bun_add_ws(self):
        reason = hook.decide(shell("bun add ws"), POLICY)
        self.assertIn("WebSocket", reason)

    def test_bun_add_sharp(self):
        reason = hook.decide(shell("bun add sharp"), POLICY)
        self.assertIn("Bun.Image", reason)

    def test_bun_add_types_ws(self):
        reason = hook.decide(shell("bun add -d @types/ws"), POLICY)
        self.assertIn("ws", reason)

    def test_bun_add_plain_package(self):
        self.assertIsNone(hook.decide(shell("bun add react"), POLICY))

    def test_bunx_tsx_blocked(self):
        reason = hook.decide(shell("bunx tsx src/index.ts"), POLICY)
        self.assertIn("TypeScript is native", reason)

    def test_pnpm_dlx(self):
        reason = hook.decide(shell("pnpm dlx create-vite"), POLICY)
        self.assertIn("bunx", reason)

    def test_import_ws(self):
        reason = hook.decide(write('import WebSocket from "ws";\n'), POLICY)
        self.assertIn("WebSocket", reason)

    def test_import_sharp(self):
        reason = hook.decide(write('import sharp from "sharp";\n'), POLICY)
        self.assertIn("Bun.Image", reason)

    def test_require_better_sqlite(self):
        reason = hook.decide(write('const db = require("better-sqlite3");\n'), POLICY)
        self.assertIn("bun:sqlite", reason)

    def test_dotenv_unnecessary(self):
        reason = hook.decide(write('import "dotenv/config";\n'), POLICY)
        self.assertIn(".env", reason)

    def test_package_json_dep(self):
        body = json.dumps({"dependencies": {"ws": "^8.18.0", "react": "19.0.0"}})
        reason = hook.decide(write(body, path="package.json"), POLICY)
        self.assertIn("ws", reason)

    def test_package_json_snippet(self):
        reason = hook.decide(
            write('"sharp": "^0.33.0"', path="package.json"), POLICY
        )
        self.assertIn("Bun.Image", reason)

    def test_allowed_imports(self):
        self.assertIsNone(
            hook.decide(write('import { Glob } from "bun";\n'), POLICY)
        )
        self.assertIsNone(hook.decide(write('import React from "react";\n'), POLICY))

    def test_echo_does_not_trip_import_scan(self):
        self.assertIsNone(hook.decide(shell('echo from "ws"'), POLICY))


class IoTests(unittest.TestCase):
    def test_deny_exit_payload(self):
        event = shell("npm install")
        reason = hook.decide(event, POLICY)
        self.assertTrue(reason)

    def test_replacements_file_exists(self):
        path = Path(__file__).with_name("replacements.json")
        data = json.loads(path.read_text(encoding="utf-8"))
        self.assertIn("ws", data["packages"])
        self.assertIn("sharp", data["packages"])
        self.assertIn("npm", data["toolchains"])


if __name__ == "__main__":
    unittest.main()
