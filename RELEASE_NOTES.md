# PortFree v1.0.0

**Kill occupied ports in seconds — not minutes.**

## What's New

### Core
- 🔍 **Scan All Listening Ports** — See every TCP LISTEN port on your system in one sidebar panel
- ⚡ **One-Click Kill** — End or force-end any process occupying a port
- 🔐 **Admin Privilege Escalation** — Auto-prompts macOS password dialog for root-owned processes
- 📋 **Copy Process Info** — One-click copy of port, PID, process name, user, and full command

### UX
- 🖥️ **Menu Bar Quick Menu** — Inspect and kill ports without leaving your current app
- ⌨️ **Global Hotkey** — `⌘⇧P` summons PortFree from anywhere
- 📌 **Custom Quick Ports** — Pin your frequently used ports for instant access
- 🔄 **Launch at Login** — Auto-start via `SMAppService`
- 🎯 **Collapsible Port List** — Large port lists collapse to 5 items with expand/collapse toggle
- 🗑️ **Clear History** — One-click clear all inspection history
- ✨ **Hover Effects** — Subtle lift and highlight on all interactive elements

### Internationalization
- 🌍 **7 Languages** — English, 简体中文, 繁體中文, 日本語, Deutsch, Français, Español
- 🔄 **Follow System Language** — Auto-detects your macOS language on first launch
- 🔤 **In-App Language Switcher** — Change language from main window or menu bar

### Technical
- No Electron, no web views — pure native SwiftUI + AppKit
- Hardened Runtime enabled, Apple notarization ready
- Non-sandboxed for full cross-process `lsof`/`kill` access
- Async pipe reads to prevent deadlocks on large port scans
- History capped at 100 entries to prevent memory growth

## System Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel

## Installation

Download `PortFree.dmg`, open it, drag PortFree to Applications.

---

# PortFree v1.0.0

**秒杀端口占用，告别命令行。**

## 新功能

### 核心
- 🔍 **全局端口扫描** — 侧边栏一览系统所有正在监听的 TCP 端口
- ⚡ **一键结束进程** — 普通结束或强制结束端口占用进程
- 🔐 **管理员提权** — root 进程自动弹出 macOS 原生密码验证框
- 📋 **一键复制信息** — 端口号、PID、进程名、用户、命令一键复制

### 体验
- 🖥️ **菜单栏快捷菜单** — 不切换应用即可检查和杀死端口
- ⌨️ **全局快捷键** — 在任何应用中按 `⌘⇧P` 唤出 PortFree
- 📌 **自定义快捷端口** — 钉住常用端口，一键查询
- 🔄 **开机自启动** — 基于 `SMAppService` 自动启动
- 🎯 **可折叠端口列表** — 超过 5 个端口自动折叠，点击展开
- 🗑️ **清除历史** — 一键清除所有查询记录
- ✨ **悬浮反馈** — 所有可交互元素均有细腻的悬浮动效

### 国际化
- 🌍 **7 种语言** — 英语、简体中文、繁體中文、日本語、Deutsch、Français、Español
- 🔄 **跟随系统语言** — 首次启动自动检测 macOS 系统语言
- 🔤 **应用内语言切换** — 主窗口和菜单栏均可切换语言

## 系统要求

- macOS 14.0（Sonoma）或更高版本
- Apple Silicon 或 Intel

## 安装

下载 `PortFree.dmg`，打开后将 PortFree 拖入"应用程序"文件夹。
