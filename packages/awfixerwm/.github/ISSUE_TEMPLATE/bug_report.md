---
name: Bug report
about: Report a bug or a crash
title: ''
type: Bug
assignees: ''

---

<!-- Please describe the issue here at the top, then fill in the system information below. -->

<!-- Attaching your full awm config can help diagnose the problem. -->
<details><summary>Config</summary>

```kdl
insert config here
```

</details> 

<!--
If you have a problem with a specific app, please verify that it is running on Wayland, rather than X11. An easy way is to run xeyes and mouse over the app: xeyes will be able to "see" only X11 windows.

You can also check what process the window PID belongs to:

$ readlink /proc/$(awm msg --json pick-window | jq .pid)/exe

If this points to xwayland-satellite, then it's an X11 window.

Please report issues with X11 apps to xwayland-satellite instead of awm: https://github.com/Supreeeme/xwayland-satellite/issues
-->

### System Information

<!-- Paste the output of `awm -V`, e.g. awm 25.02 (b94a5db) -->
* awm version: 

<!-- Write your distribution, e.g. Fedora 40 Silverblue -->
* Distro: 

<!-- Write your GPU vendor and model, e.g. AMD RX 6700M -->
* GPU: 

<!-- Write your CPU vendor and model, e.g. AMD Ryzen 7 6800H -->
* CPU:
