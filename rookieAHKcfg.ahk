; Script     rookieAHKcfg.ahk
; License:   MIT License
; Author:    Bence Markiel (bceenaeiklmr)
; Github:    https://github.com/bceenaeiklmr/rookieAHKcfg
; Date       13.10.2026
; Version    0.6.0

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

; Module imports

; Upstream Standalone Projects (Preserved as independent libraries)
#include src/MouseWindowManager/MouseWindowManager.ahk
#include src/SendTextZ/SendTextZ.ahk
#include src/StrTable/StrTable.ahk

; rookieAHKcfg Core Modules
#include src/Modules/ConfigManager.ahk
#include src/Modules/TextTools.ahk
#include src/Modules/WindowOps.ahk
#include src/Modules/WebLookups.ahk
#include src/Modules/VSCIntegration.ahk
#include src/Modules/ExplorerUtils.ahk
#include src/Modules/W32MenuManager.ahk
#include src/Modules/Abbreviations.ahk
#include src/Modules/OutlookIntegration.ahk

; Initialization

; Load user settings from config.ini
LoadConfig()
W32menu.DarkMode(true)
W32menu.PreviewIcons(false)

; Application window groups
programs := ["notepad", "notepad++", "OUTLOOK", "ms-teams", ["chrome", "firefox", "msedge"]]
for program in programs {
    if (program is Array) {
        for b in program
            GroupAdd("browser", "ahk_exe " b ".exe")
    } else if (program is String) {
        GroupAdd("wrap", "ahk_exe " program ".exe")
    }
}

; Global command hotkeys

~MButton:: W32menu.Show(400)                ; Middle mouse button (hold 400ms to show menu)
#c:: W32menu.Show()                         ; Win + C, show main menu
#w:: WinSetCenter()                         ; Win + W, center active window
#a:: WinToggleAlwaysOnTop()                 ; Win + A, toggle Always-on-Top for active window
#g:: SearchSelectedText()                   ; Win + G, open URL or search selected in Google
#t:: TranslateWeb()                         ; Win + T, translate selected text
#q:: GptSelectedText()                      ; Win + Q, open ChatGPT with selected text
^#c:: DesktopIcons(-1)                      ; Ctrl + Win + C, toggle desktop icons
^#x:: WindowNextMonitor()                   ; Ctrl + Win + X, move window to next monitor
#F1:: DisplayHotkeys()                      ; Win + F1, display cheat sheet
#PrintScreen:: PrintScreen()                ; Win + PrintScreen, capture snip

; Clipboard table formatter & abbreviation expander
^#t:: StrTableSelectedText()                ; Ctrl + Win + T, format table
^#a:: AbbreviationsSelectedText()           ; Ctrl + Win + A, expand abbreviations

; Mouse-over window sizing & transparency
#WheelUp:: CycleWindowSize(1)               ; Win + WheelUp, increase window size
#WheelDown:: CycleWindowSize(0)             ; Win + WheelDown, decrease window size
#!WheelUp:: CycleWindowTransparency(1)      ; Win + Alt + WheelUp, increase transparency
#!WheelDown:: CycleWindowTransparency(0)    ; Win + Alt + WheelDown, decrease transparency

; Hotstrings
:X*:timenow:: Send("{BackSpace}" DateNow()) ; :timenow -> insert current date and time
:X*:datenow:: Send("{BackSpace}" DateNow()) ; :datenow -> insert current date and time

; Context-sensitive hotkeys

; Outlook: Scoped CapsLock for read/unread toggle
#HotIf WinActive("ahk_exe OUTLOOK.EXE")
    CapsLock:: OutlookToggleReadState()

; String wrapping by keyboard layout
#HotIf GetKeyboardLayout() == "US"
    +':: StrWrap('""')
    +9:: StrWrap("()", "")
    {::  StrWrap("{}", "")
    [::  StrWrap("[]", "")

#HotIf GetKeyboardLayout() == "HU"
    +2::    StrWrap('""')
    +8::    StrWrap("()", "")
    <^>!b:: StrWrap("{}", "")
    <^>!f:: StrWrap("[]", "")

#HotIf GetKeyboardLayout() == "UK"
    +2:: StrWrap('""')
    +9:: StrWrap("()", "")
    {::  StrWrap("{}", "")
    [::  StrWrap("[]", "")

#HotIf GetKeyboardLayout() == "DE"
    +2::    StrWrap('""')
    +8::    StrWrap("()", "")
    <^>!7:: StrWrap("{}", "")
    <^>!8:: StrWrap("[]", "")

; YouTube: Right-click scroll seeking
#HotIf WinActive("YouTube")
    RButton & WheelUp:: Send("{Left}")      ; Scroll backward
    RButton & WheelDown:: Send("{Right}")   ; Scroll forward
    $RButton:: Click("Right")

; Web Browsers
#HotIf WinActive("ahk_group browser") && !WinActive("YouTube")
    RButton & XButton1::  Send("^{w}")      ; Close current tab
    RButton & XButton2::  Send("^{t}")      ; Open new tab
    RButton & WheelUp::   Send("^{PgUp}")   ; Previous tab
    RButton & WheelDown:: Send("^{PgDn}")   ; Next tab
    $RButton:: Click("Right")

; VLC Media Player
#HotIf WinActive("VLC media player ahk_exe vlc.exe")
    RButton & WheelUp::   VlcAcceleratedSeek("Left")
    RButton & WheelDown:: VlcAcceleratedSeek("Right")
    RButton & XButton1::  Send("p")         ; Previous track
    RButton & XButton2::  Send("n")         ; Next track
    $RButton:: Click("Right")

; Visual Studio Code
#HotIf WinActive("Visual Studio Code ahk_exe Code.exe")
    RButton & WheelUp::   Send("^{PgUp}")   ; Previous tab
    RButton & WheelDown:: Send("^{PgDn}")   ; Next tab
    $RButton:: Click("Right")

    ^#Numpad1:: VSC.Fold(1)                 ; Fold level 1
    ^#Numpad2:: VSC.Fold(2)                 ; Fold level 2
    ^!s:: VSC.Backup()                      ; Backup active file

    :*x::dev:: Run(devFolderPath)
    :*x::lib:: VSC.OpenFiles(devPrivateLib)

    :*:\n:: "``n"
    :*:\t:: "``t"
    :*:\r:: "``r``n"

#HotIf

; Helper routines

; Screen capture with fallback to Windows Snipping Tool
PrintScreen() {
    local sp
    sp := A_MyDocuments "\AutoHotkey\Lib\OCR\Examples\Example10_OCRScreenSnip.ahk"
    if FileExist(sp) {
        try return RunWait('*Launch "' sp '"')
    }
    try Run("ms-screenclip:")
}

; Format clipboard table with StrTable
StrTableSelectedText() {
    local cb
    cb := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    if ClipWait(0.4) {
        try {
            A_Clipboard := StrTable(A_Clipboard).convert()
            Send("^v")
            Sleep(150)
        }
    }
    SetTimer(() => A_Clipboard := cb, -150)
}

; Expand abbreviations in selected text
AbbreviationsSelectedText() {
    local cb, text
    cb := ClipboardAll()
    text := ClipboardGetText()
    if (text !== "") {
        A_Clipboard := TranslateAbbreviations(text)
        Send("{CtrlDown}v{CtrlUp}")
        Sleep(150)
    }
    SetTimer(() => A_Clipboard := cb, -150)
}

; Accelerated seek for VLC
VlcAcceleratedSeek(direction) {

    local currentTick, totalSteps

    static lastTick := 0
    static stepMultiplier := 1

    currentTick := A_TickCount
    if (currentTick - lastTick > 200) {
        stepMultiplier := 1
    } else {
        stepMultiplier := Min(stepMultiplier + 1, 3)
    }
    lastTick := currentTick

    totalSteps := 2 * stepMultiplier
    Send("{ShiftDown}{" . direction . " " . totalSteps . "}{ShiftUp}")
}

; Detect active keyboard layout for wrapping brackets
GetKeyboardLayout() {
    local hwnd, thrd, kbrd

    if (!WinActive("ahk_group wrap") || WinActive("ahk_group dont_wrap"))
        return ""

    hwnd := DllCall("GetForegroundWindow")
    thrd := DllCall("GetWindowThreadProcessId", "ptr", hwnd, "ptr", 0)
    kbrd := DllCall("GetKeyboardLayout", "ptr", thrd, "ptr")

    switch kbrd & 0xFFFF {
        case 0x0407: return "DE" ; German
        case 0x0409: return "US" ; English US
        case 0x040E: return "HU" ; Hungarian
        case 0x0410: return "IT" ; Italian
        case 0x0411: return "JP" ; Japanese
        case 0x0412: return "KO" ; Korean
        case 0x0413: return "NL" ; Dutch
        case 0x0415: return "PL" ; Polish
        case 0x0418: return "SK" ; Slovak
        case 0x0419: return "RU" ; Russian
        case 0x041A: return "HR" ; Croatian
        case 0x041B: return "SI" ; Slovenian
        case 0x0809: return "UK" ; English UK
        default: return ""
    }
}

; Display cheat sheet tooltip
DisplayHotkeys(timeout := 3000) {
    local cheatSheet
    cheatSheet := "
    (
    [ rookieAHKcfg Cheat Sheet ]

    Mouse Wheel:
      Right Click + Wheel  : Seek (YouTube/VLC) | Switch Tabs (Browser/VSCode)
      Win + WheelUp/Down   : Resize Window (10% increments)
      Win + Alt + Wheel    : Adjust Window Transparency

    Window Control:
      Win + W              : Center Active Window on Current Monitor
      Win + A              : Toggle Always-on-Top (Pinned)
      Ctrl + Win + X       : Move Window to Next Monitor
      Ctrl + Win + C       : Toggle Desktop Icons

    Menus & Search:
      Middle Mouse (400ms) : Show Main Win32 Menu
      Win + C              : Show Main Win32 Menu
      Win + G              : Open URL or Google Search Selected Text
      Win + T              : Google Translate Selected Text
      Win + Q              : Query ChatGPT with Selected Text
      Ctrl + Win + T       : Format Selected Text into ASCII Table
      Ctrl + Win + A       : Expand Datrak Abbreviations

    Text Utilities:
      "text", (text), {text}, [text] : Auto-wrap selected text
      :timenow / :datenow            : Insert current timestamp
    )"

    ToolTip(cheatSheet)
    while (GetKeyState("F1", "P"))
        Sleep(50)
    Sleep(timeout)
    ToolTip()
}