# PortFree 宣发文案 / Marketing Copy

---

## 一句话介绍 / One-Liner

**EN:** PortFree — Kill occupied ports in seconds, not minutes.

**CN:** PortFree — 秒杀端口占用，告别命令行。

---

## 社交媒体短文案 / Social Media Posts

### Twitter / X (EN)

> 🚀 Just shipped PortFree — a free macOS menu bar tool that lets you kill occupied ports in one click.
>
> No more `lsof | grep | kill`. Just click.
>
> ⚡ Scan all listening ports
> 🔐 Auto admin privilege escalation
> ⌨️ Global hotkey ⌘⇧P
> 🌍 7 languages
>
> Download → [link]

### Twitter / X (CN)

> 🚀 开源了一个 macOS 小工具：PortFree
>
> 再也不用 lsof + kill 了，菜单栏一键释放被占用的端口。
>
> ⚡ 扫描所有监听端口
> 🔐 root 进程自动弹密码框
> ⌨️ 全局快捷键 ⌘⇧P
> 🌍 支持 7 种语言
>
> 下载 → [link]

---

### V2EX / 少数派 (CN)

**标题：** PortFree：一个让你告别 lsof + kill 的 macOS 端口管理工具

各位开发者好，分享一个我刚做的免费开源小工具 **PortFree**。

**解决的问题：** 每次启动本地服务报"端口已占用"，都要打开终端敲 `lsof -i :3000`，再 `kill -9 PID`。PortFree 把这套流程变成了菜单栏里的一次点击。

**主要特性：**
- 自动扫描系统所有监听中的 TCP 端口，侧边栏直接展示
- 一键结束或强制结束占用进程
- root 权限进程自动弹出 macOS 原生密码框提权
- 菜单栏常驻 + 全局快捷键 ⌘⇧P
- 自定义快捷端口、历史记录、一键复制进程信息
- 支持 7 种语言（中英日德法西 + 繁体中文）
- 纯原生 SwiftUI，没有 Electron

**技术栈：** SwiftUI + AppKit，通过 lsof 和 kill 系统命令实现端口管理，SMAppService 实现开机自启，NSAppleScript 实现管理员提权。

**下载：** GitHub Releases 提供 .dmg，已签名 + 苹果公证。

欢迎试用和反馈！

---

### Hacker News / Reddit r/macapps (EN)

**Title:** PortFree – Free macOS tool to scan and kill occupied ports from your menu bar

**Post:**

I built PortFree because I got tired of the `lsof -i :3000 → kill -9 PID` dance every time I restarted a dev server.

It sits in your menu bar and lets you:
- See all listening TCP ports at a glance
- Kill any process with one click (auto-escalates to admin if needed)
- Pin your common dev ports for instant access
- Use ⌘⇧P as a global hotkey from any app

Built with SwiftUI + AppKit. No Electron. No telemetry. Fully local.

Free, open source, signed and notarized.

GitHub: [link]

---

## 应用商店 / 产品页描述 / Product Description

### EN

**PortFree** is a lightweight macOS developer tool that helps you find and kill processes occupying network ports — instantly, from your menu bar.

**For developers who are tired of typing `lsof` and `kill`.**

Enter a port number or scan all listening ports on your system. See which process is using it. End it with one click. If it's a system process, PortFree will prompt for your admin password automatically.

Features:
• Scan all TCP listening ports system-wide
• End or force-end processes with one click
• Automatic admin privilege escalation for root processes
• Menu bar quick access — no window switching needed
• Global hotkey (⌘⇧P) to summon PortFree from anywhere
• Custom quick ports for your most-used development ports
• Launch at Login support
• Copy full process details to clipboard
• Available in 7 languages

Built natively with SwiftUI. No Electron. No web views. Runs entirely on your Mac.

### CN

**PortFree** 是一款轻量级 macOS 开发者工具，帮助你从菜单栏快速找到并结束占用网络端口的进程。

**专为不想再敲 `lsof` 和 `kill` 的开发者打造。**

输入端口号或一键扫描系统所有监听端口。看到哪个进程在占用。一键结束。如果是系统进程，PortFree 会自动弹出密码框请求管理员权限。

功能亮点：
• 扫描系统所有 TCP 监听端口
• 一键结束或强制结束占用进程
• root 进程自动弹出原生密码框提权
• 菜单栏快捷操作，无需切换窗口
• 全局快捷键 ⌘⇧P，任何应用中一键唤出
• 自定义快捷端口，钉住常用开发端口
• 支持开机自启动
• 一键复制进程详细信息到剪贴板
• 支持 7 种语言

使用 SwiftUI 原生开发，没有 Electron，没有 WebView，完全在本地运行。
