<div align="center">

# ⚡ PortFree

### Free busy ports on macOS without breaking your flow

A native macOS developer tool for inspecting occupied ports, ending stuck processes, batch-cleaning listeners, checking status from the menu bar, and using a tiny CLI when you want keyboard-first control.

<p>
	<img alt="macOS" src="https://img.shields.io/badge/macOS-14%2B-111827?style=flat-square">
	<img alt="Swift" src="https://img.shields.io/badge/Swift-6-orange?style=flat-square">
	<img alt="Native UI" src="https://img.shields.io/badge/Native-SwiftUI%20%2B%20AppKit-0ea5e9?style=flat-square">
	<img alt="License" src="https://img.shields.io/badge/License-MIT-16a34a?style=flat-square">
</p>

[Features](#features) · [Screenshots](#screenshots) · [Install](#install) · [CLI](#cli) · [中文简介](#中文简介)

</div>

---

## Why PortFree

If you build web apps, APIs, local services, Electron apps, or backend tools, you have almost certainly seen this:

```bash
Error: listen EADDRINUSE: address already in use :::3000
```

The normal fix is repetitive: run `lsof`, find the PID, run `kill`, then retry your app.

PortFree replaces that workflow with a fast native interface:

- Inspect a port instantly
- See process name, PID, user, protocol, endpoint, and command
- End or force-end the process in one click
- Browse all listening ports with search and batch actions
- Keep menu bar access and CLI support ready at all times

## Screenshots

### Main experience

![PortFree overview](screenshots/%233PortFree.png)

The main window puts the full port workflow in one place: quick ports, search, batch selection, auto refresh, recent history, and detailed inspection results.

### Port detail card

![Port detail view](screenshots/%231MainPage.png)

Check whether a port is occupied and immediately see the owning process, PID, user, protocol, endpoint, and full command.

### Force end action

![Force end flow](screenshots/%232ForceEnd.png)

When a normal terminate action is not enough, PortFree gives you a clear force-end path for stubborn processes.

### Menu bar panel

![Menu bar panel](screenshots/%234MenuBarPage.png)

Use PortFree from the menu bar for quick checks without leaving your current app or opening Terminal.

### CLI workflow

![CLI helper](screenshots/%235CLIview.png)

Prefer terminal workflows? The built-in `fp` helper keeps common port actions available from the command line.

## Features

- **Port inspection** — Check whether a port is occupied and identify the exact process behind it.
- **One-click cleanup** — End or force-end the process that is holding a port.
- **All listening ports** — View every active TCP listener in one place.
- **Search and filter** — Filter by port number or process name.
- **Batch kill** — Select multiple ports and stop them together.
- **Auto refresh** — Keep the listener list updated without repeated manual scans.
- **Menu bar mode** — Quick access from a compact panel.
- **CLI included** — Use `fp` for fast command-line control.
- **Desktop widget** — See shared listening-port data at a glance.
- **Launch at login** — Keep PortFree ready after startup.
- **7 languages** — English, 简体中文, 繁體中文, 日本語, Deutsch, Français, Español.

## Install

### Download release

Download the latest `.dmg` from [Releases](../../releases).

### Run from source

1. Open `PortFree.xcodeproj`
2. Select the `PortFree` scheme
3. Build and run on macOS 14+

### Build a release package

Use the included packaging script:

```bash
./build.sh
```

Reuse an existing archive when needed:

```bash
./build.sh --skip-archive
```

## CLI

After installing the CLI helper from the app, you can use commands like:

```bash
fp 3000
fp list
fp kill 3000
```

PortFree is designed to work well for both GUI-first and terminal-first developers.

## System Requirements

- macOS 14 Sonoma or later
- Apple Silicon or Intel Mac

## Privacy

- PortFree runs locally on your Mac
- No telemetry is required for core functionality
- The main app performs port inspection and process actions locally
- The widget reads shared data from the app group container

## Tech Stack

- SwiftUI
- AppKit
- WidgetKit
- ServiceManagement
- NSAppleScript
- `/usr/sbin/lsof`
- `/bin/kill`

## 中文简介

PortFree 是一款原生 macOS 开发者工具，用来快速查看端口占用、结束卡住的进程、批量清理监听端口，并提供菜单栏面板、桌面小组件和 `fp` 命令行工具。

适合这些场景：

- `3000`、`5173`、`8080` 等开发端口被占用
- 本地服务重启失败，需要快速定位 PID
- 不想每次都手动执行 `lsof` 和 `kill`
- 想在菜单栏里快速查看当前端口状态

核心能力：

- 一键查看端口是否被占用
- 一键结束或强制结束进程
- 扫描全部监听端口
- 搜索、批量结束、自动刷新
- 菜单栏快速操作
- CLI 工具 `fp`

## License

MIT

