#!/usr/bin/env bash
# Prefer the setgid security wrapper (egid=windscribe) when NixOS module is active.
export LD_LIBRARY_PATH="@out@/opt/windscribe/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="@out@/opt/windscribe${PATH:+:$PATH}"
if [ -x /run/wrappers/bin/Windscribe ]; then
  exec /run/wrappers/bin/Windscribe "$@"
fi
exec "@out@/bin/windscribe-unwrapped" "$@"
