# awm-ipc

Types and helpers for interfacing with the [awm](https://github.com/awfixerwm/awm) Wayland compositor.

## Backwards compatibility

This crate follows the awm version.
It is **not** API-stable in terms of the Rust semver.
In particular, expect new struct fields and enum variants to be added in patch version bumps.

Use an exact version requirement to avoid breaking changes:

```toml
[dependencies]
awm-ipc = "=26.4.0"
```
