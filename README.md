# SwapPointer

A macOS utility that enables pseudo-multi-cursor support for multiple mice. Each mouse remembers its own cursor position — switching between mice warps the cursor to the last known position for that device.

## How It Works

1. Connect multiple mice to your Mac
2. SwapPointer detects each mouse via IOHIDManager
3. When you switch mice (automatically detected or via hotkey), the cursor warps to that mouse's saved position
4. Dormant cursor positions are shown as semi-transparent overlay markers

## Requirements

- macOS 26 (Tahoe) or later
- Accessibility permission (for CGEventTap)
- Input Monitoring permission (for IOHIDManager)

## Installation

### Homebrew

```bash
brew install --cask swap-pointer
```

### Manual

Download the latest release from [GitHub Releases](https://github.com/kyo-ago/swap-pointer/releases).

### Build from Source

```bash
git clone https://github.com/kyo-ago/swap-pointer.git
cd swap-pointer
swift build -c release
```

## Default Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌃⌥ Tab` | Cycle to next cursor slot |
| `⌃⌥ 1` | Switch to Slot 1 |
| `⌃⌥ 2` | Switch to Slot 2 |
| `⌃⌥ 3` | Switch to Slot 3 |

## Settings

Access settings from the menu bar icon → Settings:

- **Devices**: View connected mice and their slot assignments
- **Shortcuts**: View keyboard shortcut bindings
- **Appearance**: Toggle dormant cursor markers, adjust opacity, enable/disable warp animation
- **General**: Launch at login, auto-detection sensitivity

## Permissions

On first launch, SwapPointer will request:

1. **Accessibility** — Required for intercepting mouse events via CGEventTap
2. **Input Monitoring** — Required for identifying individual mouse devices via IOHIDManager

Grant both in System Settings → Privacy & Security.

## License

MIT
