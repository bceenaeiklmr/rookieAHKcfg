; Script     rookieAHKcfg.ahk
; License:   MIT License
; Author:    Bence Markiel (bceenaeiklmr)
; Github:    https://github.com/bceenaeiklmr/rookieAHKcfg
; Date       07.04.2025
; Version    0.3.2

#Requires AutoHotkey v2.0
#SingleInstance
#Warn

; User Settings. (see config.ini after first run)
LoadConfig()
W32menu.DarkMode(true)
W32menu.PreviewIcons(false)

; Import project.
#include src/MouseWindowManager/MouseWindowManager.ahk
#include src/sendTextZ/sendTextZ.ahk


; Command hotkeys.
~MButton:: W32menu.Show(400)                ; Middle mouse button, show on keypress.
#c:: W32menu.Show()                         ; Win + C, show main menu.
#w:: WinSetCenter()                         ; Win + W, center window.
#g:: SearchSelectedText()                   ; Win + G, search selected text in Google.
#t:: TranslateWeb()                         ; Win + T, translate selected text.
#q:: GptSelectedText()                      ; Win + Q, open ChatGPT with selected text.
^#c:: DesktopIcons(-1)                      ; Ctrl + Win + C, toggle desktop icons.
^#x:: WindowNextMonitor()                   ; Ctrl + Win + X, move window to next monitor.
#F1:: DisplayHotkeys()                      ; Win + F1, display hotkeys.

; Window hotkeys.
#WheelUp::CycleWindowSize(1)                ; Win + WheelUp, increase window size.
#WheelDown::CycleWindowSize(0)              ; Win + WheelDown, descrease window size.
#!WheelUp::CycleWindowTransparency(1)       ; Win + Alt + WheelUp, increase transparency.
#!WheelDown::CycleWindowTransparency(0)     ; Win + Alt + WheelDown, decrease transparency.

; Hotstrings.
:X*:timenow:: Send("{BackSpace}" DateNow()) ; :timenow insert the current date and time.
:X*:datenow:: Send("{BackSpace}" DateNow()) ; :datenow insert the current date and time.


; String wrap window groups.
programs := ["notepad", "notepad++", "OUTLOOK", "Chrome", "firefox"]
for program in programs {
    if (A_Index >= programs.Length - 1) {
        GroupAdd("browser", "ahk_exe " program ".exe")
    }
    GroupAdd("wrap", "ahk_exe " program ".exe")
}    
GroupAdd("dont_wrap", "regex101")


; Wrap hotkeys.
#HotIf GetKeyboardLayout() == "US"

    +':: StrWrap('""')                                          ; "selected"
    +9:: StrWrap("()", "")                                      ; (selected)
    {:: StrWrap("{}", "")                                       ; {selected}
    [:: StrWrap("[]", "")                                       ; [selected]

#HotIf GetKeyboardLayout() == "HU"
    +2:: StrWrap('""')
    +8:: StrWrap("()", "")
    <^>!b:: StrWrap("{}", "")
    <^>!f:: StrWrap("[]", "")

#HotIf GetKeyboardLayout() == "UK"
    
    +2:: StrWrap('""')
    +9:: StrWrap("()", "")
    {:: StrWrap("{}", "")
    [:: StrWrap("[]", "")

#HotIf GetKeyboardLayout() == "DE"
    
    +2:: StrWrap('""')
    +8:: StrWrap("()", "")
    <^>!7:: StrWrap("{}", "")
    <^>!8:: StrWrap("[]", "")

; YouTube hotkeys.
#HotIf WinActive("YouTube")

    Rbutton & WheelUp:: Send("{Left}")                          ; Right click + WheelUp, scroll forward.
    Rbutton & WheelDown:: Send("{Right}")                       ; Right click + WheelDown, scroll backward.
    $Rbutton:: Click("Right")                                   ; Default right click.

; Browsers hotkeys.
#HotIf WinActive("ahk_group browser") && !WinActive("Youtube")

    RButton & XButton1:: Send("{CtrlDown}w{CtrlUp}")            ; Right click + ExtraButton1, close current browser tab.
    RButton & XButton2:: Send("{CtrlDown}t{CtrlUp}")            ; Right click + ExtraButton2, open new browser tab.
    RButton & WheelUp:: Send("{CtrlDown}{PgUp}{CtrlUp}")        ; Right click + WheelUp, scroll next tab.
    RButton & WheelDown:: Send("{CtrlDown}{PgDn}{CtrlUp}")      ; Right click + WheelDown, scroll previous tab.
    $Rbutton:: Click("Right")

; VLC Media Player hotkeys.
#HotIf WinActive("VLC media player ahk_exe vlc.exe")

    RButton & WheelUp:: Send("{ShiftDown}{Left 2}{ShiftUp}")    ; Right click + WheelUp, rewind 2 * 5 secs.
    RButton & WheelDown:: Send("{ShiftDown}{Right 2}{ShiftUp}") ; Right click + WheelDown, forward 2 * 5 secs.
    RButton & Xbutton1:: Send("p")                              ; Right click + Xbutton1, prevous track.
    RButton & Xbutton2:: Send("n")                              ; Right click + Xbutton2, next track.
    $Rbutton:: Click("Right")                                   ; Default right click.

; Visual Studio Code hotkeys.
#HotIf WinActive("Visual Studio Code ahk_exe Code.exe")

    RButton & WheelUp:: Send("{CtrlDown}{PgUp}{CtrlUp}")        ; Right click + WheelUp, scroll to next project.
    RButton & WheelDown:: Send("{CtrlDown}{PgDn}{CtrlUp}")      ; Right click + WheelDown, scroll to previous project.
    $Rbutton:: Click("Right")                                   ; Default right click.
    
    ^#Numpad1:: VSC.Fold(1)                                     ; Ctrl + Win + Numpad1, change fold level to 1.
    ^#Numpad2:: VSC.Fold(2)                                     ; Ctrl + Win + Numpad2, change fold level to 2.
    ^!s:: VSC.Backup                                            ; Ctrl + Alt + s, create a backup file.

    :*x::dev:: Run(devFolderPath)                               ; :dev, open development folder in File Explorer.
    :*x::lib:: VSC.OpenFiles(devPrivateLib)                     ; :lib, open personal library in Visual Studio Code.

    :*:\n::"``n"                                                ; Insert a new line in AutoHotkey syntax.
    :*:\t::"``t"                                                ; Insert a tabulator in AutoHotkey syntax.    
    :*:\r::"``r``n"                                             ; Insert a carriage return in AutoHotkey syntax.
    
; End of case sensitive hotkeys
#HotIf


; The config's Win32menu class.
class W32menu {

    ; Enable or disable dark mode.
    static DarkMode(enable := true) {
        static current := ""
        if (enable ~= "^(0|1)$" && current !== enable) {
            Win32MenuDarkMode(enable)
            current := enable
        }
    }

    ; Show the main menu instantly or with keypress duration.
    static Show(pressDuration := 0) {
        if (!pressDuration) {
            this.main.Show()
        }
        else {
            pressed := false
            while (GetKeyState(SubStr(A_ThisHotkey, 2), "P")) {
                if (A_TimeSinceThisHotkey >= pressDuration) {
                    this.main.Show()
                    pressed := true
                }
            }
        }
    }

    ; Main menu.
    static CreateMain() {
        this.main := Menu()
        this.sys := Menu()
        this.win := Menu()
        this.vscode := Menu()
        this.strings := Menu()
        
        this.main.Add("System", this.sys)
        this.main.Add("Windows", this.win)
        this.main.Add("Visual Studio Code", this.vscode)
        this.main.Add("String", this.strings)
        
        this.main.SetIcon("System",  "imageres.dll", 194)
        if (VSC.path)
            this.main.SetIcon("Visual Studio Code",  VSC.path, 1)
        this.main.SetIcon("Windows", "shell32.dll", 315)
        this.main.SetIcon("String",  "shell32.dll", 260)
        return
    }

    ; System menu.
    static AddSysMenu() {
        this.sys.Add("My computer",  (*) => Run("::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"))
        this.sys.Add("Recycle bin",  (*) => Run("::{645FF040-5081-101B-9F08-00AA002F954E}"))
        this.sys.Add("Downloads",    (*) => Run("C:\users\" A_UserName "\Downloads"))
        this.sys.Add("My documents", (*) => Run(A_MyDocuments))
        this.sys.Add("Open desktop", (*) => Run(A_Desktop))
        this.sys.Add("Show desktop", (*) => ComObject("Shell.Application").ToggleDesktop())
        
        this.sys.SetIcon("My computer",  "imageres.dll", 194)
        this.sys.SetIcon("Recycle bin",  "imageres.dll", 50)
        this.sys.SetIcon("Downloads",    "imageres.dll", 176)
        this.sys.SetIcon("My documents", "imageres.dll", 180)
        this.sys.SetIcon("Open desktop", "imageres.dll", 180)
        this.sys.SetIcon("Show desktop", "imageres.dll", 175)
    }

    ; Fan control menu.
    static AddFanMenu() {
        
        this.fan := Menu()

        this.fan.Add("Silent",    (*) => FanControl("Silent"))
        this.fan.Add("Game",      (*) => FanControl("Game"))
        this.fan.Add("Benchmark", (*) => FanControl("Benchmark"))

        this.fan.SetIcon("Silent",    "shell32.dll", 138)
        this.fan.SetIcon("Game",      "shell32.dll", 138)
        this.fan.SetIcon("Benchmark", "shell32.dll", 138)

        this.sys.Add("Fan Control", this.fan)
        this.sys.SetIcon("Fan Control", "shell32.dll", 13)
    }

    ; Windows menu.
    static AddWinMenu() {

        local CLSID, controlPanel

        ; Master control panel creates a shortcut, it will be hidden.
        CLSID := "{ED7BA470-8E54-465E-825C-99712043E01C}"
        controlPanel := A_ScriptDir "\MasterControlPanel." CLSID
        if (!FileExist(controlPanel)) {
            DirCreate(controlPanel)
            FileSetAttrib("H", controlPanel, "D")
        }   

        this.win.Add("Hide Desktop Icons", (*) => Run(A_ScriptDir "/src/HideMyIcon/HideMyIcon_Gui.ahk"))
        this.win.Add("Master Control Panel", (*) => Run(A_ScriptDir "\MasterControlPanel." CLSID))
        this.win.Add("Registry Editor", (*) => Run("RegEdit.exe"))

        this.win.SetIcon("Hide desktop icons", "shell32.dll", 70)
        this.win.SetIcon("Master Control Panel", "shell32.dll", 315)
        this.win.SetIcon("Registry Editor", "shell32.dll", 77)
    }

    ; Visual Studio Code menu.
    static AddVSCMenu() {
        this.vscode.Add("Backup Project",    (*) => VSC.Backup())
        this.vscode.Add("Personal Library",  (*) => VSC.OpenFiles(devPrivateLib))
        this.vscode.Add("Development Drive", (*) => Run(devFolderPath))
        this.vscode.Add("Format Document",   (*) => VSC.IndentText())
        this.vscode.Add("Fold level 0",      (*) => VSC.Fold(0))
        this.vscode.Add("Fold level 1",      (*) => VSC.Fold(1))
        this.vscode.Add("Fold level 2",      (*) => VSC.Fold(2))
        this.vscode.Add("Unfold All",        (*) => VSC.UnfoldAll())
        this.vscode.Add("Unfold Comment",    (*) => VSC.UnfoldComment())
        this.vscode.Add("File new explorer", (*) => VSC.FileShowInExplorer())
        this.vscode.Add("File new instance", (*) => VSC.FileShowNewInstance())

        this.vscode.SetIcon("Backup Project",    "shell32.dll", 259)
        this.vscode.SetIcon("Personal Library",  "shell32.dll", 161)
        this.vscode.SetIcon("Development Drive", "shell32.dll", 192)
        this.vscode.SetIcon("Format Document",   "shell32.dll", 295)
        this.vscode.SetIcon("Fold level 0",      "shell32.dll", 298)
        this.vscode.SetIcon("Fold level 1",      "shell32.dll", 298)
        this.vscode.SetIcon("Fold level 2",      "shell32.dll", 298)
        this.vscode.SetIcon("Unfold All",        "shell32.dll", 147)
        this.vscode.SetIcon("Unfold Comment",    "shell32.dll", 147)
        this.vscode.SetIcon("File new explorer", "shell32.dll", 4)
        this.vscode.SetIcon("File new instance", VSC.path, 1)
    }

    ; Strings menu.
    static AddStrMenu() {
        this.strings.Add("Sort`tabc",          (*) => StrWin32MenuCopy("Sort"))
        this.strings.Add("Sort reverse`tbca",  (*) => StrWin32MenuCopy("Sort", "R"))
        this.strings.Add("Reverse`taz za",     (*) => StrWin32MenuCopy("StrReverse"))
        this.strings.Add("Upper case`tUPPER",  (*) => StrWin32MenuCopy("StrUpper"))
        this.strings.Add("Lower case`tlower",  (*) => StrWin32MenuCopy("StrLower"))
        this.strings.Add("Title case`tTitle",  (*) => StrWin32MenuCopy("StrTitle"))
        this.strings.Add("Random case`trAND",  (*) => StrWin32MenuCopy("StrRandom"))
        this.strings.Add("Inverse case`tiNV",  (*) => StrWin32MenuCopy("StrInverse"))
        this.strings.Add("Align pipe`ta|b|c",  (*) => StrWin32MenuCopy("StrAlign", "|"))
        this.strings.Add("Align comma`ta,b,c", (*) => StrWin32MenuCopy("StrAlign", ","))
        this.strings.Add("Align space`ta b c", (*) => StrWin32MenuCopy("StrAlign", " "))
        this.strings.Add("Delete empty lines`t``n``n  ``n", (*) => StrWin32MenuCopy("StrReplaceEmptyLines"))
    }

    static PreviewIcons(show := false) {

        local i, f, j, n, icons, iconSub, files, subMenu, strMenu

        static loaded := false

        if (!show || loaded)
            return

        ; credit: cyqsimon
        ; https://github.com/cyqsimon/W10-Ico-Ref
        files := [
            "shell32.dll",          ; Another collection of miscellaneous icons, including icons for internet, devices, networks, peripherals, folders, etc.
            "imageres.dll",         ; Miscellaneous icons used almost everywhere, including different types of folders, hardware devices, peripherals, actions, etc.
            "pifmgr.dll",           ; Legacy and exotic (i.e. not very useful) icons used in Windows 95 and 98.
            "explorer.exe",         ; A few icons used by Explorer and its older versions.
            "accessibilitycpl.dll", ; Icons used for accessibility.
            "ddores.dll",           ; Icons used for hardware devices and resources.
            "moricons.dll",         ; Another set of legacy icons used in pre-2000 Windows versions, mainly including icons for old applications and programming languages.
            "mmcndmgr.dll",         ; Yet another set of legacy icons, mainly including icons related to computer management, such as networks, folders, authentication, time, computers, and servers.
            "mmres.dll",            ; Icons related to audio hardware.
            "netcenter.dll",        ; A few icons related to networking.
            "netshell.dll",         ; More icons related to networking, including icons for Bluetooth, wireless routers, and network connections.
            "networkexplorer.dll",  ; A few more icons related to networking, mostly peripheral hardware related.
            "sensorscpl.dll",       ; Icons for various sensors, which mostly look the same unfortunately.
            "setupapi.dll",         ; Icons used by hardware setup wizards, including icons for various peripheral hardware.
            "wmploc.dll",           ; Icons related to multimedia, including hardware icons, MIME type icons, status icons, etc.
            "wpdshext.dll",         ; A few icons related to portable devices and portability.
            "compstui.dll",         ; Legacy icons mostly related to printing.
            "ieframe.dll",          ; All kinds of icons used by IE.
            "dmdskres.dll",         ; A few icons used for disk management.
            "dsuiext.dll",          ; Icons related to network locations and services.
            "mstscax.dll",          ; Icons used for remote desktop connection.
            "wiashext.dll",         ; Icons used for imaging hardware.
            "comres.dll",           ; Some general status icons.
            "mstsc.exe",            ; A few icons used for system monitoring and configuration.
            "actioncentercpl.dll",  ; Icons used in action center, notably including red, yellow, and green traffic lights.
            "aclui.dll",            ; A few checks, crosses, and i-in-circles.
            "autoplay.dll",         ; One autoplay icon.
            "xwizards.dll",         ; One software install icon.
            "ncpa.cpl",             ; One network folder icon.
            "url.dll"               ; A few random network related icons.
            ; Deprecated, no icons in Windows 11.
            ;"comctl32.dll",        ; Legacy info, warning, and error icons.
            ;"pnidui.dll",          ; Modern style white icons related to network status.
        ]

        ; Create a new menu for icons.
        icons := Menu()
        W32menu.main.Add("Search icons", icons)
        W32menu.main.SetIcon("Search icons", "shell32.dll", 23)

        ; Add a sub menu for each file.
        for f in files {

            iconSub := Menu()
            icons.Add(f, iconSub)

            ; Detect the number of icons in the file.
            i := 0
            loop {
                try {
                    icons.SetIcon(f, f, A_Index - 1)
                } catch {
                    break
                }
                i += 1
            }
            ; Set first icon to sub menu.
            icons.SetIcon(f, f, 0)

            ; Element per sub menu.
            n := 32
            subMenu := Ceil(i / n)

            ; Crete sub menus and add icons.
            loop subMenu {
                i := A_Index
                subMenu := Menu()
                strMenu := Format("{:03}", (i - 1) * n) " - " Format("{:03}", i * n)
                iconSub.Add(strmenu, subMenu)
                loop n {
                    try {
                        j := A_index + n * (i - 1)
                        subMenu.Add(j, (*) => "")
                        subMenu.SetIcon(j, f, j)
                    }
                    catch {
                        subMenu.Delete(j)
                        break
                    }
                }
            }
            Tooltip("Loading icon files, please wait: " AsciiProgressbarHorizontal(A_Index, files.Length))
        }
        loaded := true
        Tooltip()
        return
    }

    ; Auto-initialization of the class.
    static __New() {
        SetTitleMatchMode(2)
        this.CreateMain()
        this.AddSysMenu()
        this.AddWinMenu()
        if (VSC.path)
            this.AddVSCMenu()
        this.AddStrMenu()
        this.AddFanMenu()
    }
}

; This project is not affiliated with Microsoft or Visual Studio Code.
; It is an independent script created to enhance user experience.
class VSC {

    static ahk_lib := "C:\dev\ahk\lib\ahk_lib.ahk"

    static title := "Visual Studio Code ahk_exe Code.exe"

    static hwnds := Array()

    ; Create a backup of the current project.
    static Backup(dest := "") {

        local date, ext, filePath, name

        ext := SubStr(A_ScriptName, -4)
        name := StrReplace(VSC.Project(), ext)
        date := FormatTime(A_Now, "ddMMyy_HHmmss")
        filePath := this.FilePath()
        
        if (!dest) {
            dest := this.FileDir() "\backup\" name
        }
        if (!DirExist(dest)) {
            DirCreate(dest)
        }
        FileCopy(filePath, dest "/" name "_" date ext)
    }

    ; Create a new instance of Visual Studio Code.
    static NewInstance(files*) {
        if (!WinExist(this.title)) {
            return Run(this.path)
        }
        A_Clipboard := this.path
        Send("#r")
        WinWait("Run")
        Send("^v{Enter}")
        WinWait("Get Started")
        this.hwnds.Push(WinExist("A"))
        if (files.Length)
            this.OpenFiles(files)
    }

    ; Get the path of program executable.
    static path {
        get {

            if (this.HasOwnProp("__path"))
                return this.__path

            possiblePath := [
                A_ProgramFiles "\Microsoft VS Code\Code.exe",
                A_AppData . "\Local\Programs\Microsoft VS Code\Code.exe",
                StrReplace(A_AppData, "\Roaming") . "\Local\Programs\Microsoft VS Code\Code.exe"]

            for path in possiblePath {
                if FileExist(path) {
                    return path
                }
            }
        }
        set {
            if FileExist(value)
                this.__path := value
        }
    }

    ; Open a single, or multiple files.
    static OpenFiles(files*) {

        local cb, fileName, path

        cb := ClipboardAll()
        for v in files {
            if !(v ~= "\\|\/")
                v := A_ScriptDir "\" v
            v := StrReplace(v, "/", "\")
            if (!FileExist(v))
                continue
            path := StrSplit(v, "\")
            fileName := path[path.Length]
            A_Clipboard := StrReplace(v, fileName)
            this.FileOpen()
            WinWaitActive("Open File")
            Send(fileName        ; enter filename
                . "{F4}^a{Delete}" ; focus address bar, select all and delete
                . "^v{Enter}"      ; paste the path & enter
                . "!o")            ; open file hotkey
            WinWaitActive(fileName)
        }
        A_Clipboard := cb
    }

    ; Open a file, or files in a new editor instance.
    static OpenFileNewInstance(files*) {
        VSC()
        this.OpenFiles(files)
    }

    ; Activate editor.
    static Activate(instance := 0) {

        if !(instance > VSC.hWnds.Length) {
            hwnd := VSC.hWnds[instance]
        }
        else if (!instance) {
            hwnd := VSC.hWnds[VSC.hWnds.Length]
        }
        
        if (!WinActive(hwnd))
            WinActivate(hwnd)
    }

    ; Focus a project in the editor by a given file name.
    static FocusProject(fileName) {
        local firstProject
        firstProject := this.Project
        while (!InStr(this.Project(), fileName)) {
            Send("{CtrlDown}{PgDn}{CtrlUp}")
            Sleep(66)
            if (A_Index > 1 && firstProject = this.Project())
                return 1
        }
    }

    ; Return the file path of the current project.
    static Project() {
        return StrSplit(WinGetTitle(this.title), " - ")[1]
    }

    ; Mimic in-built hotkeys.
    static FileCreate() => this.HK("^N")
    static FileOpen() => this.HK("^O")
    static FileClose() => this.HK("^{F4}")
    static FileCloseAll() => this.HK("^K|^W")
    static FileSave() => this.HK("^S")
    static FileSaveAs() => this.HK("^+S")
    static FileSaveAll() => this.HK("^K|S")
    static FilePath() => this.HK("^K|P*")
    static FileOpenNext() => this.HK("^{Tab}")
    static FileOpenPrevious() => this.HK("^+{Tab}")
    static FileShowInExplorer() => this.HK("^K|R")
    static FileShowNewInstance() => this.HK("^K|O")
    static EditorReopen() => this.HK("^+T") ; closed editor
    static EditorPreviewModeOpen() => this.HK("^K|{Enter}")
    static IndentText() => this.HK("+!F")
    static Fold(Level := 2) => this.HK("^A|^K|^" level)
    static UnfoldAll() => this.HK("^K|^J")
    static UnfoldComment() => this.HK("^K|^{NumpadDiv}")
    static Filedir() => SubStr(StrReplace(this.FilePath(), this.Project()), 1, -1)
    static Opendir() => Run(this.Filedir())
    
    ; A function to execute editor hotkeys.
    static HK(keys) {
        clip := (keys ~= "\*") ? 1 : 0
        keys := StrSplit(StrReplace(keys, "*"), "|")
        ; Copypath has to be performed twice.
        loop (clip) ? 2 : 1 {
            for k, v in keys {
                Send(Format("{:L}", v))
                if (k !== keys.Length)
                    Sleep(100)
            }
        }
        if (clip)
            return A_Clipboard
        return
    }

    ; Create a new instance of Visual Studio Code.
    static Call() {
        VSC.NewInstance()
    }

    ; Auto-initialization of the class.
    static __New() {
        if (A_TitleMatchMode !== 2)
            SetTitleMatchMode(2)
        if WinExist(this.title)
            this.hWnds.Push(WinExist("A"))
    }
}

; Load the configuration file.
LoadConfig() {
    global devFolderPath, devPrivateLib
    configFile := A_ScriptDir "\config.ini"
    if (FileExist(configFile)) {
        devFolderPath := IniRead(configFile, "Settings", "devFolderPath")
        devPrivateLib := IniRead(configFile, "Settings", "devPrivateLib")
    }
    else {
        MsgBox("Config file created, it will be opened after pressing OK.`n`n"
            "Please set your variables.`n`n"
            "( you can skip this step, and this message will not appear again )"
            , "rookieAHKcfg - missing config file", 0x40)
        IniWrite("C:\", configFile, "Settings", "devFolderPath")
        IniWrite("C:\dev", configFile, "Settings", "devPrivateLib")
        Run(A_ScriptDir "\config.ini")
    }
}

; Copy the selected text to the clipboard and return it.
ClipboardGetText(restore := 1, timeout := .4) {

    local c, cbSaved

    ; Save clipboard.
    if (restore) {
        cbSaved := ClipBoardAll()
    }

    ; Copy the selected text.   
    A_Clipboard := ""
    c := ""
    Sleep(20)
    Send("{CtrlDown}c{CtrlUp}")
    if (ClipWait(timeout, 0)) {
        c := A_Clipboard
    }

    ; Restore clipboard.
    if (restore) {
        A_Clipboard := cbSaved
    }
    return c
}

; Paste a string from the clipboard, restore content, auto reselect.
ClipboardPaste(str, restore := true, reselect := false) {

    local cbSaved
    
    ; Save clipboard.
    cbSaved := ClipboardAll()

    ; Copy text. Paste requires a delay.
    A_Clipboard := str
    Send("{CtrlDown}v{CtrlUp}")
    Sleep(200)
    
    ; Reselect text.
    if (reselect) {
        Send("{ShiftDown}{Left " StrLen(str) "}{ShiftUp}")
    }

    ; Restore clipboard.
    if (restore) {
        A_Clipboard := cbSaved
    }
    return
}

; Toggle desktop icons visibility.
DesktopIcons( Show:=-1 ) {
    ; credit: SKAN
    ; https://www.autohotkey.com/boards/viewtopic.php?t=75890

    Local hProgman := WinExist("ahk_class WorkerW", "FolderView") ? WinExist()
                   :  WinExist("ahk_class Progman", "FolderView")

    Local hShellDefView := DllCall("user32.dll\GetWindow", "ptr",hProgman,      "int",5, "ptr")
    Local hSysListView  := DllCall("user32.dll\GetWindow", "ptr",hShellDefView, "int",5, "ptr")

    If ( DllCall("user32.dll\IsWindowVisible", "ptr",hSysListView) != Show )
         DllCall("user32.dll\SendMessage", "ptr",hShellDefView, "ptr",0x111, "ptr",0x7402, "ptr",0)
}

DisplayHotkeys(timeout := 3000) {
    local str := "
    (
    Browser, Youtube, VLC, Visual Studio Code
    Right click + WheelUp, scroll forward

    Middle mouse button, show main menu on keypress.
    Win + C, show main menu.
    Win + F1, display hotkeys.
    
    Win + G, search selected text in Google.
    Win + T, translate selected text.
    Win + Q, open ChatGPT with selected text.
    Win + W, center window.

    Ctrl + Win + C, toggle desktop icons.
    Ctrl + Win + X, move window to next monitor.
    
    Win + WheelUp, increase window size.
    Win + WheelDown, descrease window size.
    Win + Alt + WheelUp, increase transparency.
    Win + Alt + WheelDown, decrease transparency.

    :timenow insert the current date and time.
    :datenow insert the current date and time.

    Selected texts can be wrapped with the following characters:
    "selected"
    (selected)
    {selected}
    [selected]
    In notepad++, Outlook, Chrome, Firefox.
    )"
    
    ToolTip(str)
    while (GetKeyState("F1", "P"))
        Sleep(100)
    Sleep(timeout)
    ToolTip()
}

; Return the current date and time in the specified format.
DateNow(fmt := "dd.MM.yy. HH:mm:ss") {
    return FormatTime(A_Now, fmt)
}

; Check if the given year is a leap year.
IsLeapYear(year := 0) {
    y := (!year) ? A_Year : year
    return !Mod(y, 100) && !Mod(y, 400) || !Mod(y, 4) ? 1 : 0
}

; Calculates the start and end date of the given week.
DateFromCalendarWeek(year := 0, week := 0) {

    ; Validate date parameters.
    if (!year)
        year := A_YYYY

    if (!week) {
        week := SubStr(A_YWeek, -2)
        if (week > 1)
            week -= 1
    }
    else {
        if (1 > week || week > 52)
            return
    }

    ; Find the first Monday in the year.
    date := year "0101"
    isMonday := false
    while (!isMonday) {
        isMonday := FormatTime(date++ " L0x9", "WDay")
    }

    ; Caulcate start-end days of the given week.
    start := SubStr(DateAdd(date, (week - 1) * 7, "Days"), 1, 8)
    end := SubStr(DateAdd(start, 6, "Days"), 1, 8)
    return [start, end]
}

; Formats seconds to hours, minutes and seconds.
FormatSeconds(sec) {
    local h, m, s
    h := sec // 3600
    m := Mod(sec, 3600) // 60
    s := Mod(sec, 60)
    return Format("{:02}:{:02}:{:02}", h, m, s)
}

; Open FanControl with the given configuration.
FanControl(cfg) {
    
    local path := "C:\Program Files (x86)\FanControl\"
    
    ; Extension.
    if (SubStr(cfg, -5) != ".json") {
        cfg .= ".json"
    }
    
    ; File exists.
    if (!FileExist(path "/configurations/" cfg)) {
        MsgBox("File not found: " cfg)
        return
    }
    
    ; Operation can be cancelled by the user, raises an error.
    try Run(path "/FanControl.exe -c " cfg)
}

; Hide the window when pressing Win + G.
GameBarHide() {

    ; cls = "ahk_class ApplicationFrameWindow"
    ; exe = "ahk_exe explorer.exe"
    static txt := "Game Bar"

    wd := A_WinDelay
    SetWinDelay(0)   
    hwnd := WinExist("A")

    while true {
        try {
            MouseGetPos(, , &hwnd2, &hCtrl, 2)
            if (txt == ControlGetText(hCtrl, hWnd2)) {
                WinHide(hCtrl)
                WinClose(hCtrl)
                WinActivate(hwnd)
                SetWinDelay(wd)
                return
            }
        }
        if (A_Index > 2**8)
            return
    }
}

; Get the current keyboard layout.
GetKeyboardLayout() {
    
    if (!WinActive("ahk_group wrap") || WinActive("ahk_group dont_wrap"))
        return

    hwnd := DllCall("GetForegroundWindow")
    thrd := DllCall("GetWindowThreadProcessId", "ptr", hwnd, "ptr", 0)
    kbrd := DllCall("GetKeyboardLayout", "ptr", thrd, "ptr") 

    switch kbrd & 0xFFFF {
        case 0x0407 : kbrd := "DE" ; German
        case 0x0409 : kbrd := "US" ; English, United States
        case 0x040E : kbrd := "HU" ; Hungarian
        case 0x0410 : kbrd := "IT" ; Italian
        case 0x0411 : kbrd := "JP" ; Japanese
        case 0x0412 : kbrd := "KO" ; Korean
        case 0x0413 : kbrd := "NL" ; Dutch
        case 0x0415 : kbrd := "PL" ; Polish
        case 0x0418 : kbrd := "SK" ; Slovak
        case 0x0419 : kbrd := "RU" ; Russian
        case 0x041A : kbrd := "HR" ; Croatian
        case 0x041B : kbrd := "SI" ; Slovenian
        case 0x0809 : kbrd := "UK" ; English, United Kingdom
        default: kbrd := "Not supported: " kbrd
    }
    return kbrd    
}

; Copy, paste a selected text as a Gpt prompt.
GptSelectedText(save := true) {

    local cb, str, path

    cb := ClipboardGetText()
    
    Run("https://chatgpt.com/")
    Sleep(1000)
    Send(cb "{Enter}")

    if (save) {
        str := Format("{:02}.{:02}.{:02} {:02}:{:02}:{:02}`t{}"
        , A_DD, A_MM, SubStr(A_YYYY, 3, 2), A_Hour, A_Min, A_Sec, cb)
        path := A_MyDocuments "\gpt_stats.txt"
        FileAppend(str "`n", path)
    }
    return
}

; Align a string by the given delimiter.
StrAlign(str, delimRow := "`n", delimCol := "|") {

    ; Remove empty lines, trailing newlines.
    str := StrReplaceEmptyLines(str)

    ; Parse by line and column.
    text := []
    loop parse str, delimRow {
        if (A_LoopField ~= "\d|\w") {
            line := StrSplit(A_LoopField, delimCol)
            text.Push(line)
        }
    }

    ; Get lengths.
    lengths := []
    for v in line
        lengths.push(0)
    for line in text {
        for col in line {
            if (len := StrLen(col)) > lengths[A_Index]
                lengths[A_Index] := len
        }
    } 

    ; Align text.
    ret := ""
    for line in text {
        for col in line {
            align := (A_Index !== line.Length) ? 1 : 0
            ret .= (align ? StrLenghten(col, lengths[A_Index]) : col)
                .  (align ? delimCol : "`n")
        }
    }
    return SubStr(ret, 1, -1)
}

; Wrap, unwrap the selected text with the given character.
StrWrap(char := "", filler := "") {

    local c, cb, cbSaved

    ; Save clipboard.
    if (A_Clipboard) {
        cbSaved := ClipBoardAll()
        A_Clipboard := ""
    }

    ; Copy selected text.
    Send("{CtrlDown}c{CtrlUp}")
    if ClipWait(0.15, 0) {
        cb := A_Clipboard
        c := StrSplit(char)

        ; Append or replace.
        if !InStr(cb, c[1] . filler) && !InStr(cb, c[2] . filler) {
            A_ClipBoard := c[1] . filler . cb . filler . c[2]
        }
        else {
            A_Clipboard := StrReplace(StrReplace(cb, c[1]), c[2])
        }
        Send("{CtrlDown}v{CtrlUp}")
        Sleep(200)
    }
    else {
        Send(Char)
    }

    ; Restore clipboard.
    if IsSet(cbSaved) {
        A_ClipBoard := cbSaved
    }
}

; Convert a string to lower case.
StrLower(str) {
    return Format("{:L}", str)
}

; Convert a string to upper case.
StrUpper(str) {
    return Format("{:U}", str)
}

; Convert a string to title case.
StrTitle(str) {
    return Format("{:T}", str)
}

; Convert a string to random case.
StrRandom(str) {
    local s := ""
    Loop Parse, str {
        s .= Format("{:" (Random(0, 1) ? "U" : "L") "}", A_LoopField)
    }
    return s
}

; Convert a string to the opposite case.
StrInverse(str) {
    local s, f
    Loop Parse, str {
        f := A_LoopField
        s .= (Format("{:" (Format("{:U}", f) == f) ? "L" : "U") "}", f)
    }
    return s
}

; Reverse a string.
StrReverse(input) {
    local str := ""
    loop Parse, input {
        str .= SubStr(input, StrLen(input) - A_index + 1, 1)
    }
    return str
}

; Add padding to the string to the right.
StrLenghten(str, len, char := " ") {
    loop len - StrLen(str)
        str .= char
    return str
}

; Remove empty lines and trailing newline in a string.
StrReplaceEmptyLines(str) {
    ; Replace CRLF with LF, delete empty lines
    str := StrReplace(str, "`r`n", "`n")
    str := StrReplace(str, "`n`n", "`n")
    
    ; Remove trailing newline (e.g.: Excel copy)
    if (SubStr(str, -1) == "`n")
        str := SubStr(str, 1, -1)
    return str
}

; Copy the selected text to the clipboard and call a function with it.
StrWin32MenuCopy(fn, params*) {

    local cb

    ; Save clipboard.
    cb := ClipboardAll()

    ; Copy selected, call function, paste.
    A_Clipboard := ""
    Send("{CtrlDown}c{CtrlUp}")
    if (ClipWait(.25, 0)) {
        params.InsertAt(1, A_Clipboard)
        A_Clipboard := (%fn%)(params*)
        Send("{CtrlDown}v{CtrlUp}")
        Sleep(100)
    }
    ; Restore clipboard.
    A_Clipboard := cb
    return
}

; Move a window to the next monitor.
WindowNextMonitor() {

    local i, mon, left, top, right, bot, x, y, w, h, m

    ; Get monitors.
    mon := []
    loop MonitorGetCount() {
        try {
            MonitorGet A_Index, &left, &top, &right, &bot
            mon.Push({x : left, y : top, w : right - left, h : bot - top})
        } catch
            MsgBox("Monitor " A_Index ", error occurred.")
    }
    ; Get current window position.
    WinGetPos(&x, &y, &w, &h, "A")
    for v in mon {
        m := mon[A_Index]
        if (x >= m.x && m.x + m.w >= x) {
            i := A_Index + 1 > mon.Length ? 1 : A_Index + 1
            break
        }
    }
    ; Resize to fit target monitor.
    w := Min(w, mon[i].w)
    h := Min(h, mon[i].h)
    x := mon[i].x + (mon[i].w - w) // 2
    y := mon[i].y + (mon[i].h - h) // 2
    WinMove(x, y, w, h, "A")
    return
}

; Center a window, activate.
WinSetCenter(title := "A", activate := true) {
    
    local hwnd, w, h, x, y
    
    ; Restore window if minimized.
    hwnd := WinExist(title)
    DllCall("ShowWindow", "UInt", hwnd, "UInt", SW_RESTORE:=9)
    
    ; Get window position, center.
    WinGetPos(, , &w, &h, hwnd)
    x := (A_ScreenWidth - w) // 2
    y := (A_ScreenHeight - h) // 2
    WinMove(x, y, , , hwnd)
    
    if (activate && !WinActive(hwnd))
        WinActivate(hwnd)
}

; Search the selected text in the default browser.
SearchSelectedText(save := true) {

    static text := "Game Bar"

    ; The following hack is required to make GameBar window invisible for the
    ; user, which is activated by pressing Win + G automatically.
    wd := A_WinDelay
    SetWinDelay(0)
    hwnd := WinExist("A")

    cb := ClipboardGetText(, .25)
    
    while true {
        try {
            MouseGetPos(,, &hwnd2, &hCtrl, 2)
            if (text == ControlGetText(hCtrl, hwnd2)) {
                WinHide(hCtrl)
                WinClose(hCtrl)
                WinActivate(hwnd)
                break
            }
        }
    }

    Run("https://www.google.com/search?q=" cb)
    SetWinDelay(wd)

    if (save) {
        str := Format("{:02}.{:02}.{:02} {:02}:{:02}:{:02}`t{}"
            , A_DD, A_MM, SubStr(A_YYYY, 3, 2), A_Hour, A_Min, A_Sec, cb)
        filePath := A_MyDocuments "\google_stats.txt"
        FileAppend(str "`n", filePath)
    }
    
    return
}

; Translate the selected text using Google Translate.
TranslateWeb(languageDisplay := "en", languageSource := "auto", languageTarget := "auto") {
    
    local cb, cbSaved, params

    cbSaved := ClipBoardAll()
    cb := ClipBoardGetText()
    A_Clipboard := cbSaved

    ; URIEncode automatically converted by the browser.
    params := "?hl=" languageDisplay
        . "&eotf=0"
        . "&sl=" languageSource
        . "&tl=" languageTarget
        . "&text=" cb
        . "&op=translate"
    
    Run("https://translate.google.com/" params)
}

; Enable or disable dark mode on Win32 menu.
Win32MenuDarkMode(dark := true) {
    ; Credit: lexikos
    ; https://www.autohotkey.com/boards/viewtopic.php?t=94661
    ; https://stackoverflow.com/a/58547831/894589

    if (VerCompare(A_OSVersion, "10.0.18362") < 0)
        return

    uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
    SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
    FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
    DllCall(SetPreferredAppMode, "int", dark) ; *** 0 for NOT Dark
    DllCall(FlushMenuThemes)
    return
}
