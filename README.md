# rookieAHKcfg

**rookieAHKcfg** is a beginner-friendly AutoHotkey script. My daily config file.
  
Utilizes the mouse wheel, hotkeys, and clipboard tools to improve your workflow.
  
It’s easily customizable, with no AHK experience required.

- Scroll through browser tabs, editor projects with the mouse wheel.
- Seek through YouTube and VLC videos with the mouse wheel.
- Search, translate, or modify selected text.
- Mouse over window resize, transparency change.
- Move the window to the next window with a hotkey.
- Format strings, wrap/unwrap text, and insert emojis via menu or hotstrings.
- Built to be simple, fast, and easy to remember.

![rookieAHKcfg_Win32Menu](https://github.com/user-attachments/assets/c3bbe0a0-edd4-4e74-bba6-2fe4e70efbee)

## Setup

1. [Install AutoHotkey](https://www.autohotkey.com/) (v2.0).
2. Download this repo.
3. Run `rookieAHKcfg.ahk`.
4. Press `Win + F1` to see the cheat sheet.

## Features

### Mouse actions

- **Right Click + Wheel Scroll**  
- Seek on YouTube, VLC videos  
- Switch tabs in Chrome/Firefox  
- Navigate files or projects in VS Code  
- Seek in VLC and other media players  

### Hotkeys

| Hotkey             | Action                                  |
|--------------------|-----------------------------------------|
| `Win + C`          | Show main menu                          |
| `Win + G`          | Google selected text                    |
| `Win + T`          | Translate selected text                 |
| `Win + Q`          | Open ChatGPT with selected text         |
| `Win + W`          | Center active window                    |
| `Ctrl + Win + C`   | Toggle desktop icons                    |
| `Ctrl + Win + X`   | Move window to next monitor             |
| `Win + F1`         | View hotkey cheat sheet                 |


### Mouse over window control

| Hotkey                  | Action                             |
|-------------------------|------------------------------------|
| `Win + Wheel Up / Down` | Resize windows on the fly.         |
| `Win + Alt + Wheel`     | Adjust transparency instantly.     |


### String things

- Wrap/Unwrap Strings: `[text]`, `"text"`, `{text}`, `(text)` formats.
- String Reformatting: `select text` → `change case`, `align`, or `sort`.

### Emoji & symbol Library

- 150+ emojis, ASCII art, and symbols.
- Paste anywhere instantly or call by hotstring.
- Included my previous project [**SendTextZ**](https://github.com/bceenaeiklmr/SendTextZ)  

### Hide My Icon – clean desktop

- Hide or adjust the visibility and transparency of the desktop icons.
- Integrated GUI for [**HideMyIcon**](https://github.com/bceenaeiklmr/HideMyIcon)

### VS Code shortcuts

- Open file in Explorer, new editor instance
- Fold/Unfold code

### Visual Win32 Menu

- Don't like memorizing hotkeys?  
- Use a menu to explore features easily.

## Credit:

- Huge thanks to the AutoHotkey community for years of inspiration.  
- Win32 dark menu, **lexikos**: https://www.autohotkey.com/boards/viewtopic.php?t=94661  
- DesktopIcons, **SKAN**: https://www.autohotkey.com/boards/viewtopic.php?t=75890
