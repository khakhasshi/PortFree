# PortFree — Mac App Store Edition

Port commands, ready to paste.

PortFree generates Terminal commands for inspecting or ending processes listening on TCP ports. This edition does not scan or end processes from inside the app.

## Getting started
1. Enter a port such as 5173, or several ports such as 3000, 5173, 8080.
2. Choose Inspect, End process (SIGTERM), or Force end (SIGKILL).
3. Review the command and click Copy command, or press Shift-Command-C.
4. Open Terminal, paste the command, review it, and press Return.
5. End commands display the target PIDs and require you to type y before they send a signal.

Inspect first. Force ending a process can discard unsaved work. Stopping a process may affect every service it hosts. The commands use your current user's permissions and do not automatically elevate privileges. PortFree cannot determine whether a command you run in Terminal succeeds.

## Features
Quick port presets, up to 32 TCP ports per command, input validation, full command preview, a menu bar panel, and recently copied ports within the current session. Commands use the macOS lsof, sort, and kill tools and are tested with zsh and bash.

## Troubleshooting
- Invalid ports: use numbers from 1 to 65535, separated by commas or spaces.
- No listening PIDs: the port may not have a TCP listener visible to your user. Read any lsof errors shown in Terminal.
- Permission denied: the process may belong to another user. PortFree does not request administrator access.
- A process restarts: a service manager may relaunch it. Stop it through the tool that started it.
- UDP is not included: the current commands target TCP listeners.

Requires macOS 14 or later. English (US).

## Contact
Email contact@jiangjingzhe.com for support. Include your macOS and PortFree versions and a description of the issue. Never include credentials or private command output.
