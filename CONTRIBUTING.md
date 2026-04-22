# Contributing to PortFree

Thanks for your interest in contributing! Here's how to get started.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Open `PortFree.xcodeproj` in Xcode 16+
4. Select the `PortFree` scheme and build (⌘B)

## Development Requirements

- macOS 14.0+ (Sonoma)
- Xcode 16+
- Swift 6
- Apple Developer account (for signing)

## Project Structure

```
PortFree/              # Main app source
  ContentView.swift    # Main window UI
  MenuBarView.swift    # Menu bar panel
  PortManagerViewModel.swift  # Core logic & PortInspector
  Localization.swift   # 7-language dictionary
  PortFreeShared.swift # App ↔ Widget shared data
  Resources/
    fp                 # CLI bash script
    PortFree.help/     # Apple Help Book
PortFreeWidget/        # WidgetKit extension
build.sh               # One-command archive + sign + DMG
```

## Pull Request Guidelines

### Before Submitting

- [ ] Build succeeds without errors (⌘B)
- [ ] Test on macOS 14+ (both light and dark mode)
- [ ] If adding UI, verify all 7 languages render correctly
- [ ] If modifying `PortInspector`, test with real ports (e.g. `python3 -m http.server 8000`)

### PR Format

**Title:** Brief description of the change (e.g. "Fix CLI list parsing for IPv6 addresses")

**Body:**
- What does this PR do?
- Why is this change needed?
- Any breaking changes?

### Code Style

- Follow existing SwiftUI patterns in the codebase
- Use `@MainActor` for view models and UI-related code
- Mark pure static helpers as `nonisolated`
- Keep localization keys in `AppTextKey` enum with translations for all 7 languages
- Prefer `replace_string_in_file` style minimal diffs

### What We Accept

- Bug fixes
- Performance improvements
- New language translations
- UI polish and accessibility improvements
- CLI (`fp`) enhancements

### What Needs Discussion First

Open an issue before starting work on:

- New major features
- Architecture changes
- Dependency additions
- Breaking changes to CLI interface

## Building a Release

```bash
./build.sh              # Full archive + sign + DMG
./build.sh --skip-archive  # Reuse existing archive
```

## Reporting Issues

Include:
- macOS version
- PortFree version
- Steps to reproduce
- Expected vs actual behavior
- Console logs if relevant (`Console.app` → filter "PortFree")

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
