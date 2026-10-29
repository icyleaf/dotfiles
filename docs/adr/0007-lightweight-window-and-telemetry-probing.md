# ADR-0007: Lightweight Window and Telemetry Probing in Omarchy Plugins

**Status**: Accepted  
**Date**: 2026-10-19

## Context

On multi-monitor setups (e.g. 3 displays: eDP, HDMI, DP), each display hosts an independent instance of the status bar. High-frequency or unconstrained inspection within bar plugins can cause massive fork storms and push system CPU load over 15:

1. **`icyleaf.workspaces` Process Storm**: The widget scanned process trees using `pstree -p <pid>` to resolve TUI app icons inside terminals. However, the probe unconditionally inspected the largest window of every occupied workspace every 3 seconds, targeting multi-process GUI apps (Chrome, Thunderbird, VS Code, WeChat) with hundreds of threads. This consumed 200%+ CPU and caused defunct processes.
2. **`icyleaf.resources` Telemetry Lag**: The `status.sh` telemetry script called `nvidia-smi` whenever the binary was present on PATH, even on AMD/Intel systems without an active NVIDIA driver kernel module (hanging and returning code 9). It also invoked `sensors`, which suffered I/O timeouts on hardware sensors such as DDR5 `spd5118`. Together, each `status.sh` execution took 700ms–1300ms, running simultaneously across 3 bars every 2 seconds.

## Decision

1. **Terminal-Gated Window Probing in `icyleaf.workspaces`**:
   - Introduce `AppIconModel.isTerminalClass()` with a curated list of Wayland/Linux terminal emulator classes (`kitty`, `alacritty`, `foot`, `ghostty`, `com.mitchellh.ghostty`, `wezterm`, `gnome-terminal`, `st`, etc.), plus support for user-configured `terminalClasses`.
   - Gate process-tree probing in `Widget.qml` so only windows matching a terminal class are queued. GUI applications are never probed with `pstree`.
   - Add `-T` to `pstree` (`pstree -T -p <pid>`) to suppress thread hierarchy inspection, reducing scan overhead on multi-threaded terminal hosts by ~80%.
   - Increase default probing interval from 3s to 5s (`probeIntervalMs: 5000`).

2. **Device-Guarded Telemetry & Direct Sysfs Reading in `icyleaf.resources`**:
   - Check `/dev/nvidiactl` character device node before calling `nvidia-smi`. On AMD/Intel hardware, fall back directly to reading DRM GPU busy percentage from `/sys/class/drm/card*/device/gpu_busy_percent`.
   - Remove `sensors` CLI dependency. Read CPU temperatures directly in a single pass over `/sys/class/hwmon` (matching `k10temp`, `coretemp`, `zenpower`, or `acpitz`).
   - Read composite sensor (`temp1_input`) for NVMe devices to prevent redundant PCIe SMART queries.
   - Use shell built-in file reads (`< "$file"` / `read -r`) and `/proc/stat` CPU core counting to eliminate subprocess forks.
   - Adjust default `refreshSeconds` from 2s to 3s.

## Reasons

- **Drastic Latency & Load Reduction**: `status.sh` execution time dropped from 1272ms to ~60ms (a 95% reduction), completely eliminating sensor timeouts and failed driver calls.
- **Zero Waste on Non-Terminals**: Routine desktop workloads with browser, editor, and chat windows produce zero `pstree` invocations.
- **Thread Suppression**: Terminal probes become lightweight (~10ms–70ms) by avoiding enumeration of internal worker threads.
- **Scales cleanly across multiple monitors**: 3 bars running every 3s impose negligible system footprint (<1% CPU combined).

## Trade-offs Accepted

- Non-standard terminal emulators whose window class does not match the built-in list must be explicitly declared in the widget settings (`terminalClasses`).
- Telemetry refresh is 3 seconds by default instead of 2 seconds, which remains more than responsive for human-facing desktop status bars.
