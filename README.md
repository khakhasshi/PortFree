<div align="center">

# ⚡ PortFree

**Kill occupied ports in seconds — not minutes.**

A lightweight macOS menu bar utility for developers who are tired of typing `lsof` and `kill` every time a port is stuck.

[English](#features) · [简体中文](#功能特性)

</div>

## Screenshots

| Main Window | Menu Bar |
|---|---|
| ![Main Window](screenshots/main-window.png) | ![Menu Bar](screenshots/menubar-panel.png) |

| Port Occupied Detail | All Listening Ports |
|---|---|
| ![Port Occupied](screenshots/port-occupied.png) | ![Scan All](screenshots/scan-all-ports.png) |

---

## Features

- **Scan All Listening Ports** — See every TCP port in use on your system at a glance. No terminal needed.
- **One-Click Kill** — Select a port, click "End Process" or "Force End". Done.
- **Admin Privilege Escalation** — If a process requires root, PortFree automatically prompts for your password via macOS native dialog.
- **Menu Bar Quick Access** — Always available from your menu bar. Inspect and kill ports without switching apps.
- **Global Hotkey** — Press `⌘⇧P` from anywhere to summon PortFree instantly.
- **Custom Quick Ports** — Pin your frequently used ports (3000, 5173, 8080…) for one-tap inspection.
- **Launch at Login** — Start automatically when you log in. Always ready.
- **Copy Process Info** — One click to copy port, PID, process name, user, and command to clipboard.
- **7 Languages** — English, 简体中文, 繁體中文, 日本語, Deutsch, Français, Español.

## Why PortFree?

Every developer has been here:

```
Error: listen EADDRINUSE: address already in use :::3000
```

Then you open Terminal, type `lsof -i :3000`, find the PID, type `kill -9 12345`, and hope it works. PortFree replaces that entire flow with **one click**.

| Before PortFree | With PortFree |
|---|---|
| Open Terminal | Click the menu bar icon |
| `lsof -i :3000` | See the port is occupied |
| Find the PID | Click "End Process" |
| `kill -9 <PID>` | ✅ Done |
| 30+ seconds | **< 3 seconds** |

## Installation

### Download

Download the latest `.dmg` from [Releases](../../releases).

### Homebrew (coming soon)

```bash
brew install --cask portfree
```

## System Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel

## Tech Stack

- **SwiftUI** + **AppKit** for native macOS experience
- **ServiceManagement** (`SMAppService`) for Launch at Login
- System commands: `/usr/sbin/lsof`, `/bin/kill`
- **NSAppleScript** for admin privilege escalation
- **NSEvent** global monitor for hotkey support
- No Electron. No web views. Pure native.

## Privacy & Security

- PortFree runs **entirely locally**. No data is sent anywhere.
- No App Sandbox — required to inspect and manage processes across the system.
- Hardened Runtime enabled for notarization compatibility.
- Signed and notarized with Apple Developer ID.

## License

MIT

---

<div align="center">

# ⚡ PortFree

**秒杀端口占用，告别命令行。**

一款轻量级 macOS 菜单栏开发者工具，专为被"端口已被占用"折磨的你而生。

</div>

---

## 功能特性

- **一览全局** — 自动扫描系统所有正在监听的 TCP 端口，侧边栏直接展示。
- **一键结束** — 选中端口，点击"结束进程"或"强制结束"，立即释放。
- **管理员提权** — 遇到 root 进程自动弹出 macOS 原生密码验证框，无需手动 sudo。
- **菜单栏常驻** — 不占 Dock 位置，随时从菜单栏快速操作。
- **全局快捷键** — 在任何应用中按 `⌘⇧P` 即刻唤出 PortFree。
- **自定义快捷端口** — 把你常用的端口钉在侧边栏，一键查询。
- **开机自启动** — 登录即启动，永远待命。
- **一键复制** — 端口号、PID、进程名、用户、命令等信息一键复制到剪贴板。
- **7 种语言** — 英语、简体中文、繁體中文、日本語、Deutsch、Français、Español。

## 为什么选择 PortFree？

每个开发者都经历过这一幕：

```
Error: listen EADDRINUSE: address already in use :::3000
```

然后打开终端，敲 `lsof -i :3000`，找到 PID，再 `kill -9 12345`。PortFree 把这套流程变成了 **一次点击**。

| 没有 PortFree | 使用 PortFree |
|---|---|
| 打开终端 | 点击菜单栏图标 |
| `lsof -i :3000` | 直接看到端口被占用 |
| 找到 PID | 点击"结束进程" |
| `kill -9 <PID>` | ✅ 搞定 |
| 30 秒以上 | **不到 3 秒** |

## 安装

### 下载

从 [Releases](../../releases) 下载最新 `.dmg`。

### Homebrew（即将支持）

```bash
brew install --cask portfree
```

## 系统要求

- macOS 14.0（Sonoma）或更高版本
- Apple Silicon 或 Intel

## 隐私与安全

- PortFree **完全在本地运行**，不会向任何服务器发送数据。
- 未启用 App Sandbox（检测和管理跨进程端口需要此权限）。
- 已启用 Hardened Runtime，符合苹果公证要求。
- 使用 Apple Developer ID 签名并公证。
