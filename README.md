# rookieAHKcfg

**rookieAHKcfg** is a modular, daily-driver AutoHotkey v2 configuration designed for speed, ergonomics, and productivity.

It integrates mouse wheel shortcuts, window tiling, terminal launching, developer string transformations, and clipboard tools into a seamless daily workflow.

![rookieAHKcfg_Win32Menu](https://github.com/user-attachments/assets/c3bbe0a0-edd4-4e74-bba6-2fe4e70efbee)

---

## Highlights

- **Mouse Wheel Navigation**: Scroll through browser tabs, VS Code editor tabs, and seek YouTube/VLC media with Right Click + Scroll.
- **Window Management**: Center windows, pin Always-on-Top (`Win + A`), move between monitors across multi-display setups (`Ctrl + Win + X`), and resize/transparency on the fly.
- **Integrated Terminal Launcher**: Launch Command Prompt or PowerShell (standard or elevated Admin) directly in the active File Explorer folder.
- **Smart Web Actions**: Selected text opens directly if it's a URL, or performs sanitized searches in Google (`Win + G`), Google Translate (`Win + T`), or ChatGPT (`Win + Q`).
- **Developer Text Tools**: Case converters (`camelCase`, `snake_case`, `kebab-case`, `PascalCase`), path formatters (`/`, `\`, `\\`), safe delimiter alignment, and bracket auto-wrapping.
- **Emoji & Symbol Library**: 150+ emojis, ASCII art, and symbols with the integrated [**SendTextZ**](https://github.com/bceenaeiklmr/SendTextZ) engine.
- **Smooth Desktop Fader**: Modernized [**HideMyIcon**](https://github.com/bceenaeiklmr/HideMyIcon) with hardware-accelerated quadratic ease-out transitions and 0% idle CPU shell hook.
- **Win32 Dark Menu**: Access any action or setting visually by holding Middle Mouse for 400ms or pressing `Win + C`.

---

## Setup & Requirements

1. [Install AutoHotkey v2](https://www.autohotkey.com/) (v2.0 or newer).
2. Clone or download this repository.
3. Run `rookieAHKcfg.ahk`.
4. Press `Win + F1` at any time to view the built-in cheat sheet.

---

## Hotkeys Quick Reference

### Window & Screen Controls

| Hotkey | Action | Description |
|---|---|---|
| `Win + W` | Center Window | Centers active window in current monitor's work area |
| `Win + A` | Pin Window | Toggles Always-on-Top with visual badge feedback |
| `Ctrl + Win + X` | Next Monitor | Moves active window to next monitor (retaining maximized state) |
| `Ctrl + Win + C` | Desktop Icons | Instantly toggles Windows desktop icons visibility |
| `Win + Wheel Up / Down` | Resize Window | Steps window size up or down in 10% increments |
| `Win + Alt + Wheel` | Window Opacity | Adjusts active window transparency on the fly |

### Search & Text Utilities

| Hotkey | Action | Description |
|---|---|---|
| `Win + G` | Smart URL / Search | Opens URL directly in browser, or searches Google |
| `Win + T` | Google Translate | Opens Google Translate with selected text |
| `Win + Q` | ChatGPT Prompt | Opens ChatGPT with selected text as pre-filled query |
| `Ctrl + Win + T` | ASCII Table | Converts selected CSV/pipe table into clean ASCII table |
| `Ctrl + Win + A` | Expand Abbreviations | Expands project and company acronyms with descriptions |
| `Win + F1` | Cheat Sheet | Displays hotkey quick reference tooltip |

### Mouse Actions (Context-Sensitive)

| Application | Mouse Combination | Action |
|---|---|---|
| **YouTube** | Right Click + Wheel | Seek forward / backward |
| **Browsers** | Right Click + Wheel | Switch between tabs |
| **Browsers** | Right Click + Extra 1/2 | Close tab (`Ctrl+W`) / Open tab (`Ctrl+T`) |
| **VLC Media Player** | Right Click + Wheel | Accelerated media seek |
| **VLC Media Player** | Right Click + Extra 1/2 | Previous / Next track |
| **VS Code** | Right Click + Wheel | Switch between active editor tabs |

---

## Project Architecture

`rookieAHKcfg` is built with a clean, modular architecture:

```text
rookieAHKcfg/
├── rookieAHKcfg.ahk               # Central orchestrator & hotkey bindings (~240 lines)
├── config.ini                     # User configuration & preferences
├── abbreviations.example.txt      # Abbreviations dictionary template (auto-seeds abbreviations.txt)
├── src/
│   ├── Modules/                   # rookieAHKcfg core modules
│   │   ├── ConfigManager.ahk      # Safe settings loader & startup shortcut manager
│   │   ├── TextTools.ahk          # Safe align, inverse, wrap, developer cases & paths
│   │   ├── WindowOps.ahk          # Center, next monitor, always-on-top, desktop icons
│   │   ├── WebLookups.ahk         # Smart URL detection, URI encoding, Google & ChatGPT
│   │   ├── ExplorerUtils.ahk      # File Explorer tab/path inspection & terminal launchers
│   │   ├── VSCIntegration.ahk     # Visual Studio Code CLI instance & backup controls
│   │   ├── W32MenuManager.ahk     # Win32 dark menu, icon browser, conditional fan control
│   │   ├── Abbreviations.ahk      # Safe abbreviation expander
│   │   └── OutlookIntegration.ahk # Scoped Outlook read/unread COM toggle
│   │
│   ├── MouseWindowManager/        # Upstream standalone mouse resize & transparency tool
│   ├── SendTextZ/                 # Upstream standalone text & emoji hotstrings engine
│   ├── HideMyIcon/                # Upstream standalone desktop icon auto-hider & GUI
│   └── StrTable/                  # Upstream standalone ASCII table generator
```

---

## Integrated Standalone Projects

The subdirectories in `src/` are maintained as standalone repositories:
- [**MouseWindowManager**](https://github.com/bceenaeiklmr/MouseWindowManager) - Window resize & opacity cycling.
- [**SendTextZ**](https://github.com/bceenaeiklmr/SendTextZ) - Text snippets, Roman numerals, ASCII art, and symbols.
- [**HideMyIcon**](https://github.com/bceenaeiklmr/HideMyIcon) - Desktop icon fader with GpGFX quadratic ease-out transitions.
- [**StrTable**](https://github.com/bceenaeiklmr/StrTable) - ASCII/Markdown table generator (AutoHotkey & Python).

---

## Credits & Acknowledgments

- **lexikos**: [Win32 dark menu theme](https://www.autohotkey.com/boards/viewtopic.php?t=94661) & AutoHotkey v2.
- **SKAN**: [DesktopIcons visibility toggle](https://www.autohotkey.com/boards/viewtopic.php?t=75890).
- **iseahound**: [Explorer.ahk](https://github.com/iseahound/Explorer.ahk) for File Explorer active tab, path extraction, and shell inspection (with contributions from Lexikos, TheCrether, and mikeyww).
- The AutoHotkey community for years of open-source tools and inspiration.

---

## License

This project is licensed under the [MIT License](LICENSE).
