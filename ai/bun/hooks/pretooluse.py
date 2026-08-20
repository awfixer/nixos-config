#!/usr/bin/env python3
"""PreToolUse: reject non-Bun JS toolchains and packages Bun already ships."""

from __future__ import annotations

import json
import os
import re
import shlex
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = Path(
    os.environ.get("CLAUDE_PLUGIN_ROOT")
    or os.environ.get("GROK_PLUGIN_ROOT")
    or HERE.parent
)

WRAPPERS = {
    "sudo",
    "doas",
    "command",
    "env",
    "nice",
    "nohup",
    "stdbuf",
    "unbuffer",
    "time",
    "timeout",
    "ionice",
    "chronic",
    "eatmydata",
    "busybox",
}

DURATION = re.compile(
    r"^(?:\d+(?:\.\d+)?(?:s|m|h|ms)?|\d+:\d+(?::\d+)?)$", re.IGNORECASE
)
ENV_ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=.*")
IMPORT_FROM = re.compile(
    r"""(?:export\s+.*?from|from|require\s*\(|import\s*\()\s*['"]([^'"]+)['"]""",
    re.DOTALL,
)
SIDE_EFFECT_IMPORT = re.compile(r"""(?:^|\n)\s*import\s+['"]([^'"]+)['"]""")
DEP_LINE = re.compile(
    r"""['"]([^'"]+)['"]\s*:\s*['"](?:[\^~>=<\d*]|workspace:|file:|link:|http|git|npm:)"""
)

SHELL_EVENTS = {
    "bash",
    "run_terminal_command",
    "shell",
    "local_shell",
}


def load_policy() -> dict:
    path = HERE / "replacements.json"
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


def package_index(packages: dict) -> dict[str, tuple[str, dict]]:
    index = {}
    for name, info in packages.items():
        index[name.lower()] = (name, info)
        for alias in info.get("aliases") or []:
            index[alias.lower()] = (name, info)
    return index


def deny(reason: str) -> int:
    payload = {
        "decision": "deny",
        "reason": reason,
        "systemMessage": reason,
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
        },
    }
    sys.stdout.write(json.dumps(payload, ensure_ascii=False) + "\n")
    return 2


def allow() -> int:
    sys.stdout.write('{"decision":"allow"}\n')
    return 0


def split_shell_segments(command: str) -> list[str]:
    segments: list[str] = []
    buf: list[str] = []
    quote = None
    i = 0
    n = len(command)
    while i < n:
        ch = command[i]
        if quote:
            if ch == "\\" and quote != "'" and i + 1 < n:
                buf.append(command[i : i + 2])
                i += 2
                continue
            buf.append(ch)
            if ch == quote:
                quote = None
            i += 1
            continue
        if ch in "'\"`":
            quote = ch
            buf.append(ch)
            i += 1
            continue
        if command.startswith("&&", i) or command.startswith("||", i):
            segments.append("".join(buf))
            buf = []
            i += 2
            continue
        if ch in ";|&\n":
            segments.append("".join(buf))
            buf = []
            i += 1
            continue
        buf.append(ch)
        i += 1
    segments.append("".join(buf))
    return [s.strip() for s in segments if s.strip()]


def tokenize(segment: str) -> list[str]:
    try:
        return shlex.split(segment, posix=True)
    except ValueError:
        return segment.split()


def basename_cmd(token: str) -> str:
    name = token.strip()
    if name.startswith("\\"):
        name = name[1:]
    name = os.path.basename(name)
    lower = name.lower()
    for suffix in (".exe", ".cmd", ".bat", ".ps1"):
        if lower.endswith(suffix):
            name = name[: -len(suffix)]
            break
    return name


def skip_wrappers(tokens: list[str]) -> list[str]:
    i = 0
    n = len(tokens)
    while i < n:
        raw = tokens[i]
        if ENV_ASSIGN.match(raw):
            i += 1
            continue
        name = basename_cmd(raw).lower()
        if name in WRAPPERS:
            i += 1
            while i < n:
                t = tokens[i]
                if t.startswith("-"):
                    i += 1
                    continue
                if name in {"timeout", "time"} and DURATION.match(t):
                    i += 1
                    continue
                if ENV_ASSIGN.match(t):
                    i += 1
                    continue
                break
            continue
        break
    return tokens[i:]


def command_and_args(segment: str) -> tuple[str | None, list[str]]:
    tokens = skip_wrappers(tokenize(segment))
    if not tokens:
        return None, []
    return basename_cmd(tokens[0]).lower(), tokens[1:]


def spec_to_package(spec: str) -> str | None:
    spec = spec.strip()
    if not spec or spec.startswith((".", "/", "~", "node:", "bun:", "data:", "http:", "https:", "git+", "github:", "file:", "workspace:")):
        return None
    if spec.startswith("npm:"):
        spec = spec[4:]
    if spec.startswith("@"):
        rest = spec[1:]
        if "/" not in rest:
            return None
        scope, name = rest.split("/", 1)
        name = name.split("@")[0].split("/")[0]
        if not scope or not name:
            return None
        return f"@{scope}/{name}"
    return spec.split("@")[0].split("/")[0]


def bun_add_packages(args: list[str]) -> list[str]:
    flags_with_value = {
        "-c",
        "--config",
        "--cwd",
        "--filter",
        "-F",
        "--backend",
        "--linker",
        "--registry",
        "--omit",
        "--cpu",
        "--os",
        "--auth",
    }
    pkgs: list[str] = []
    i = 0
    while i < len(args):
        t = args[i]
        if t in flags_with_value:
            i += 2
            continue
        if t.startswith("-"):
            i += 1
            continue
        name = spec_to_package(t)
        if name:
            pkgs.append(name)
        i += 1
    return pkgs


def suggest_toolchain(exe: str, args: list[str], toolchains: dict) -> str:
    info = toolchains[exe]
    mapping = info.get("map") or {}
    if exe in {"npx", "pnpx"}:
        rest = " ".join(args)
        return f"bunx {rest}".rstrip()
    if exe in {"tsx", "ts-node", "ts-node-esm"}:
        rest = " ".join(args)
        return f"bun {rest}".rstrip()
    if exe == "nodemon":
        rest = " ".join(args)
        return f"bun --watch {rest}".rstrip()
    if exe in {"node", "nodejs"}:
        rest = " ".join(args)
        return f"bun {rest}".rstrip()
    if exe == "deno":
        if args and args[0] == "run":
            return f"bun {' '.join(args[1:])}".rstrip()
        return "bun"
    if args:
        sub = args[0]
        if sub in {"-v", "-V", "--version", "version"}:
            return "bun --version"
        if sub in mapping:
            rest = " ".join(args[1:])
            return f"{mapping[sub]} {rest}".rstrip()
        if not sub.startswith("-") and exe in {"npm", "pnpm", "yarn", "yarnpkg"}:
            return f"bun run {' '.join(args)}".rstrip()
    return info.get("use") or "bun"


def package_reason(name: str, canonical: str, info: dict) -> str:
    use = info["use"]
    docs = info.get("docs")
    shown = name if name == canonical else f"{name} (alias of {canonical})"
    msg = f"Do not use the `{shown}` package. Bun already provides this: {use}."
    if docs:
        msg += f" {docs}"
    return msg


def check_shell(command: str, policy: dict) -> str | None:
    toolchains = policy["toolchains"]
    packages = package_index(policy["packages"])
    for segment in split_shell_segments(command):
        exe, args = command_and_args(segment)
        if not exe:
            continue
        if exe in toolchains:
            suggested = suggest_toolchain(exe, args, toolchains)
            base = toolchains[exe]["reason"]
            return f"Blocked `{exe}`. {base} Use: `{suggested}`."
        if exe in {"bun", "bunx"}:
            bun_args = args
            if exe == "bunx":
                pkgs = bun_add_packages(bun_args)
            elif bun_args and bun_args[0] in {"add", "install", "i", "remove", "rm", "uninstall"}:
                pkgs = bun_add_packages(bun_args[1:])
            else:
                pkgs = []
            for pkg in pkgs:
                hit = packages.get(pkg.lower())
                if hit:
                    canonical, info = hit
                    return package_reason(pkg, canonical, info)
    return None


def check_text(text: str, policy: dict) -> str | None:
    packages = package_index(policy["packages"])
    specs: list[str] = []
    for match in IMPORT_FROM.finditer(text):
        specs.append(match.group(1))
    for match in SIDE_EFFECT_IMPORT.finditer(text):
        specs.append(match.group(1))
    for spec in specs:
        name = spec_to_package(spec)
        if not name:
            continue
        hit = packages.get(name.lower())
        if hit:
            canonical, info = hit
            return package_reason(name, canonical, info)
    try:
        parsed = json.loads(text)
    except (json.JSONDecodeError, TypeError):
        parsed = None
    dep_names: list[str] = []
    if isinstance(parsed, dict):
        for key in (
            "dependencies",
            "devDependencies",
            "optionalDependencies",
            "peerDependencies",
        ):
            block = parsed.get(key)
            if isinstance(block, dict):
                dep_names.extend(str(k) for k in block)
    else:
        for match in DEP_LINE.finditer(text):
            dep_names.append(match.group(1))
    for name in dep_names:
        hit = packages.get(name.lower())
        if hit:
            canonical, info = hit
            return package_reason(name, canonical, info)
    return None


def tool_input(event: dict) -> dict:
    inp = event.get("toolInput") or event.get("tool_input") or {}
    return inp if isinstance(inp, dict) else {}


def tool_name(event: dict) -> str:
    return str(event.get("toolName") or event.get("tool_name") or "")


def collect_strings(value, acc: list[str], skip: set[str] | None = None) -> None:
    skip = skip or {"old_string", "oldString", "old_str"}
    if isinstance(value, dict):
        for key, inner in value.items():
            if key in skip:
                continue
            collect_strings(inner, acc, skip)
    elif isinstance(value, list):
        for inner in value:
            collect_strings(inner, acc, skip)
    elif isinstance(value, str) and value.strip():
        acc.append(value)


def is_shell_tool(name: str, inp: dict) -> bool:
    lowered = name.lower()
    if lowered in SHELL_EVENTS:
        return True
    # Claude/Grok aliases in matchers already rewrite Bash → run_terminal_command,
    # but a bare payload with only `command` and an empty tool name is still a shell call.
    return not name and isinstance(inp.get("command") or inp.get("cmd"), str)


def decide(event: dict, policy: dict) -> str | None:
    name = tool_name(event)
    inp = tool_input(event)
    if is_shell_tool(name, inp):
        command = inp.get("command") or inp.get("cmd")
        if isinstance(command, str) and command.strip():
            return check_shell(command, policy)
        return None
    texts: list[str] = []
    collect_strings(inp, texts)
    blob = "\n".join(texts)
    if blob.strip():
        return check_text(blob, policy)
    return None


def main() -> int:
    try:
        raw = sys.stdin.read()
        event = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        return allow()
    if not isinstance(event, dict):
        return allow()
    try:
        policy = load_policy()
        reason = decide(event, policy)
    except Exception as exc:  # fail-open on hook bugs
        sys.stderr.write(f"bun hook error: {exc}\n")
        return allow()
    if reason:
        return deny(reason)
    return allow()


if __name__ == "__main__":
    raise SystemExit(main())
