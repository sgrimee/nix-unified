# Sway + Rofi Keybinding Cheat Sheet

**Modifier Key:** `Alt` (Mod1) - Left Alt key or both Alt keys

## Core Window Management

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Alt + Return` | Open terminal | Launch ghostty terminal |
| `Alt + Shift + q` | Close window | Kill the focused window |
| `Alt + Shift + c` | Reload config | Reload sway configuration |
| `Alt + Shift + e` | Exit sway | Show exit confirmation dialog |

## Navigation & Focus

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Alt + h` | Focus left | Move focus to window on the left |
| `Alt + j` | Focus down | Move focus to window below |
| `Alt + k` | Focus up | Move focus to window above |
| `Alt + l` | Focus right | Move focus to window on the right |
| `Alt + Left` | Focus left | Alternative arrow key navigation |
| `Alt + Down` | Focus down | Alternative arrow key navigation |
| `Alt + Up` | Focus up | Alternative arrow key navigation |
| `Alt + Right` | Focus right | Alternative arrow key navigation |

## Moving Windows

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Alt + Shift + h` | Move left | Move window to the left |
| `Alt + Shift + j` | Move down | Move window down |
| `Alt + Shift + k` | Move up | Move window up |
| `Alt + Shift + l` | Move right | Move window to the right |
| `Alt + Shift + Left` | Move left | Alternative arrow key moving |
| `Alt + Shift + Down` | Move down | Alternative arrow key moving |
| `Alt + Shift + Up` | Move up | Alternative arrow key moving |
| `Alt + Shift + Right` | Move right | Alternative arrow key moving |

## Workspaces

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Alt + 1-9,0` | Switch workspace | Switch to workspace 1-10 |
| `Alt + Shift + 1-9,0` | Move to workspace | Move container to workspace 1-10 |

## Layout Controls

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Alt + b` | Split horizontal | Next window splits horizontally |
| `Alt + v` | Split vertical | Next window splits vertically |
| `Alt + s` | Stacking layout | Arrange windows in stacking mode |
| `Alt + w` | Tabbed layout | Arrange windows in tabbed mode |
| `Alt + e` | Toggle split | Toggle between split layouts |
| `Alt + f` | Fullscreen | Toggle fullscreen for focused window |
| `Alt + Shift + Space` | Toggle floating | Toggle floating mode for focused window |
| `Alt + Space` | Focus mode toggle | Toggle focus between tiling and floating |
| `Alt + a` | Focus parent | Focus the parent container |

## Resize Mode

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Alt + r` | Enter resize mode | Enter window resize mode |

**In resize mode:**
- `h` / `Left`: Shrink width
- `j` / `Down`: Grow height  
- `k` / `Up`: Shrink height
- `l` / `Right`: Grow width
- `Enter` / `Escape`: Exit resize mode

## Application Launchers & Rofi

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Alt + d` | App launcher | Launch applications (rofi drun mode) |
| `Alt + Shift + d` | Run command | Execute commands from PATH (rofi run mode) |
| `Alt + Tab` | Window switcher | Switch between open windows (rofi window mode) |
| `Alt + Shift + s` | SSH launcher | Quick SSH connections (rofi ssh mode) |
| `Alt + p` | Combined launcher | Search apps and commands together (rofi combi mode) |

### Rofi Navigation
- **Type** to filter results
- **Arrow keys** or **j/k** to navigate
- **Enter** to select
- **Escape** to cancel
- **Tab** to switch between modes (when sidebar is shown)

## System Controls

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Print` | Screenshot | Take a screenshot with grim |

### Audio Controls
| Keybinding | Action | Description |
|------------|--------|-------------|
| `XF86AudioMute` | Toggle mute | Mute/unmute default sink |
| `XF86AudioLowerVolume` | Volume down | Decrease volume by 5% |
| `XF86AudioRaiseVolume` | Volume up | Increase volume by 5% |
| `XF86AudioMicMute` | Mic toggle | Mute/unmute microphone |

### Brightness Controls
| Keybinding | Action | Description |
|------------|--------|-------------|
| `XF86MonBrightnessDown` | Brightness down | Decrease brightness by 5% |
| `XF86MonBrightnessUp` | Brightness up | Increase brightness by 5% |

## Rofi Features

### Available Modes
- **drun**: Desktop applications with icons and descriptions
- **run**: Command line executables from PATH
- **window**: Switch between open windows
- **ssh**: Quick SSH connection launcher
- **combi**: Combined search across apps and commands

### Theme Features
- **Icons**: Application icons shown in launcher
- **Modern design**: Catppuccin-inspired dark theme
- **Sidebar**: Mode switcher on the side
- **Search**: Fuzzy search with history
- **Custom fonts**: FiraCode Nerd Font for consistency

### Usage Tips
- Type partial names to quickly find applications
- Use the sidebar to switch between different rofi modes
- SSH mode automatically reads from `~/.ssh/config`
- Window mode shows window titles and workspaces
- History remembers frequently used items

---

**Configuration Location:** `/home/sgrimee/.config/nix/nix-unified/modules/home-manager/wl-sway.nix`