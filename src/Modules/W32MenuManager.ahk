#Requires AutoHotkey v2.0

class W32menu {
    static main := ""
    static sys := ""
    static win := ""
    static vscode := ""
    static strings := ""
    static devCases := ""
    static paths := ""
    static terminals := ""
    static fan := ""

    ; Enable or disable dark mode
    static DarkMode(enable := true) {
        static current := ""
        if (enable ~= "^(0|1)$" && current !== enable) {
            Win32MenuDarkMode(enable)
            current := enable
        }
    }

    ; Show main menu with optional keypress duration (using non-blocking KeyWait)
    static Show(pressDuration := 0) {
        if (!pressDuration) {
            this.main.Show()
        } else {
            key := RegExReplace(A_ThisHotkey, "^[~*$#+^!]+")
            if !KeyWait(key, "T" (pressDuration / 1000)) {
                this.main.Show()
                KeyWait(key)
            }
        }
    }

    ; Initialize menus
    static CreateMain() {
        this.main := Menu()
        this.sys := Menu()
        this.win := Menu()
        this.vscode := Menu()
        this.strings := Menu()
        this.devCases := Menu()
        this.paths := Menu()

        this.main.Add("System", this.sys)
        this.main.Add("Windows", this.win)
        if (VSC.path)
            this.main.Add("Visual Studio Code", this.vscode)
        this.main.Add("String", this.strings)

        this.main.SetIcon("System", "imageres.dll", 194)
        if (VSC.path)
            this.main.SetIcon("Visual Studio Code", VSC.path, 1)
        this.main.SetIcon("Windows", "shell32.dll", 315)
        this.main.SetIcon("String", "shell32.dll", 260)
    }

    ; System shortcuts
    static AddSysMenu() {
        this.sys.Add("My computer",  (*) => Run("::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"))
        this.sys.Add("Recycle bin",  (*) => Run("::{645FF040-5081-101B-9F08-00AA002F954E}"))
        this.sys.Add("Downloads",    (*) => Run(A_MyDocuments "\..\Downloads"))
        this.sys.Add("My documents", (*) => Run(A_MyDocuments))
        this.sys.Add("Open desktop", (*) => Run(A_Desktop))
        this.sys.Add("Show desktop", (*) => ComObject("Shell.Application").ToggleDesktop())

        this.sys.SetIcon("My computer",  "imageres.dll", 194)
        this.sys.SetIcon("Recycle bin",  "imageres.dll",  50)
        this.sys.SetIcon("Downloads",    "imageres.dll", 176)
        this.sys.SetIcon("My documents", "imageres.dll", 180)
        this.sys.SetIcon("Open desktop", "imageres.dll", 180)
        this.sys.SetIcon("Show desktop", "imageres.dll", 175)
    }

    ; Fan control profiles
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

    ; Windows tools
    static AddWinMenu() {
        CLSID := "{ED7BA470-8E54-465E-825C-99712043E01C}"
        controlPanel := A_ScriptDir "\MasterControlPanel." CLSID
        if (!FileExist(controlPanel)) {
            try {
                DirCreate(controlPanel)
                FileSetAttrib("H", controlPanel, "D")
            }
        }

        ; Terminals submenu (opens in active Explorer folder if focused)
        this.terminals := Menu()
        this.terminals.Add("Command Prompt",         (*) => LaunchCmd(false))
        this.terminals.Add("Command Prompt (Admin)", (*) => LaunchCmd(true))
        this.terminals.Add("PowerShell",             (*) => LaunchPowerShell(false))
        this.terminals.Add("PowerShell (Admin)",     (*) => LaunchPowerShell(true))

        this.terminals.SetIcon("Command Prompt",         "cmd.exe", 1)
        this.terminals.SetIcon("Command Prompt (Admin)", "cmd.exe", 1)
        this.terminals.SetIcon("PowerShell",             "powershell.exe", 1)
        this.terminals.SetIcon("PowerShell (Admin)",     "powershell.exe", 1)

        this.win.Add("Terminals", this.terminals)
        this.win.Add("Always on Top`tWin+A", (*) => WinToggleAlwaysOnTop())
        this.win.Add("Hide Desktop Icons", (*) => Run(A_ScriptDir "/src/HideMyIcon/HideMyIcon_Gui.ahk"))
        this.win.Add("Master Control Panel", (*) => Run("shell:::" CLSID))
        this.win.Add("Registry Editor", (*) => Run("regedit.exe"))

        this.win.SetIcon("Terminals", "cmd.exe", 1)
        this.win.SetIcon("Always on Top`tWin+A", "shell32.dll", 248)
        this.win.SetIcon("Hide Desktop Icons", "shell32.dll", 70)
        this.win.SetIcon("Master Control Panel", "shell32.dll", 315)
        this.win.SetIcon("Registry Editor", "shell32.dll", 77)
    }

    ; VS Code actions
    static AddVSCMenu() {
        if (!VSC.path)
            return

        this.vscode.Add("Backup Project",    (*) => VSC.Backup())
        this.vscode.Add("Personal Library",  (*) => VSC.OpenFiles(devPrivateLib))
        this.vscode.Add("Development Drive", (*) => Run(devFolderPath))
        this.vscode.Add("Format Document",   (*) => VSC.IndentText())
        this.vscode.Add("Fold level 1",      (*) => VSC.Fold(1))
        this.vscode.Add("Fold level 2",      (*) => VSC.Fold(2))
        this.vscode.Add("Unfold All",        (*) => VSC.UnfoldAll())
        this.vscode.Add("Unfold Comment",    (*) => VSC.UnfoldComment())
        this.vscode.Add("File in Explorer",  (*) => VSC.FileShowInExplorer())
        this.vscode.Add("New Instance",      (*) => VSC.NewInstance())

        this.vscode.SetIcon("Backup Project",    "shell32.dll", 259)
        this.vscode.SetIcon("Personal Library",  "shell32.dll", 161)
        this.vscode.SetIcon("Development Drive", "shell32.dll", 192)
        this.vscode.SetIcon("Format Document",   "shell32.dll", 295)
        this.vscode.SetIcon("Fold level 1",      "shell32.dll", 298)
        this.vscode.SetIcon("Fold level 2",      "shell32.dll", 298)
        this.vscode.SetIcon("Unfold All",        "shell32.dll", 147)
        this.vscode.SetIcon("Unfold Comment",    "shell32.dll", 147)
        this.vscode.SetIcon("File in Explorer",  "shell32.dll", 4)
        this.vscode.SetIcon("New Instance",      VSC.path, 1)
    }

    ; String transformations & developer helpers
    static AddStrMenu() {
        ; Developer Cases Submenu
        this.devCases.Add("camelCase",       (*) => StrWin32MenuCopy("StrCamelCase"))
        this.devCases.Add("PascalCase",      (*) => StrWin32MenuCopy("StrPascalCase"))
        this.devCases.Add("snake_case",      (*) => StrWin32MenuCopy("StrSnakeCase"))
        this.devCases.Add("SCREAMING_SNAKE", (*) => StrWin32MenuCopy("StrScreamingSnake"))
        this.devCases.Add("kebab-case",      (*) => StrWin32MenuCopy("StrKebabCase"))

        ; Path Separators Submenu
        this.paths.Add("Forward Slash (/)", (*) => StrWin32MenuCopy("StrPathSlash"))
        this.paths.Add("Backslash (\)",     (*) => StrWin32MenuCopy("StrPathBackslash"))
        this.paths.Add("Escaped (\\)",      (*) => StrWin32MenuCopy("StrPathEscaped"))

        this.strings.Add("Developer Cases", this.devCases)
        this.strings.Add("Path Format",     this.paths)
        this.strings.Add() ; Separator

        this.strings.Add("Sort`tabc",          (*) => StrWin32MenuCopy("Sort"))
        this.strings.Add("Sort reverse`tbca",  (*) => StrWin32MenuCopy("Sort", "R"))
        this.strings.Add("Reverse`taz za",     (*) => StrWin32MenuCopy("StrReverse"))
        this.strings.Add("Upper case`tUPPER",  (*) => StrWin32MenuCopy("StrUpper"))
        this.strings.Add("Lower case`tlower",  (*) => StrWin32MenuCopy("StrLower"))
        this.strings.Add("Title case`tTitle",  (*) => StrWin32MenuCopy("StrTitle"))
        this.strings.Add("Random case`trAND",  (*) => StrWin32MenuCopy("StrRandom"))
        this.strings.Add("Inverse case`tiNV",  (*) => StrWin32MenuCopy("StrInverse"))
        this.strings.Add("Align pipe`ta|b|c",  (*) => StrWin32MenuCopy("StrAlign", , "|"))
        this.strings.Add("Align comma`ta,b,c", (*) => StrWin32MenuCopy("StrAlign", , ","))
        this.strings.Add("Align space`ta b c", (*) => StrWin32MenuCopy("StrAlign", , " "))
        this.strings.Add("Delete empty lines", (*) => StrWin32MenuCopy("StrReplaceEmptyLines"))
        this.strings.Add("Format comment",     (*) => StrWin32MenuCopy("StrFormatComment", 80))
    }

    ; Visual icon browser
    static PreviewIcons(show := false) {
        static loaded := false
        if (!show || loaded)
            return

        files := [
            "shell32.dll", "imageres.dll", "pifmgr.dll", "explorer.exe",
            "accessibilitycpl.dll", "ddores.dll", "mmres.dll", "netcenter.dll"
        ]

        icons := Menu()
        this.main.Add("Search icons", icons)
        this.main.SetIcon("Search icons", "shell32.dll", 23)

        for f in files {
            iconSub := Menu()
            icons.Add(f, iconSub)

            i := 0
            loop {
                try {
                    icons.SetIcon(f, f, A_Index - 1)
                } catch {
                    break
                }
                i += 1
            }
            icons.SetIcon(f, f, 0)

            n := 32
            subMenuCount := Ceil(i / n)
            loop subMenuCount {
                idx := A_Index
                subM := Menu()
                strRange := Format("{:03}", (idx - 1) * n) " - " Format("{:03}", idx * n)
                iconSub.Add(strRange, subM)
                loop n {
                    try {
                        j := A_Index + n * (idx - 1)
                        subM.Add(j, (*) => "")
                        subM.SetIcon(j, f, j)
                    } catch {
                        subM.Delete(j)
                        break
                    }
                }
            }
        }
        loaded := true
        return
    }

    static HasFanControl() {
        return FileExist("C:\Program Files (x86)\FanControl\FanControl.exe")
            || FileExist(A_ProgramFiles "\FanControl\FanControl.exe")
    }

    static __New() {
        SetTitleMatchMode(2)
        this.CreateMain()
        this.AddSysMenu()
        this.AddWinMenu()
        this.AddVSCMenu()
        this.AddStrMenu()
        if (this.HasFanControl())
            this.AddFanMenu()
    }
}

; Launch FanControl profile
FanControl(cfg) {
    path := "C:\Program Files (x86)\FanControl\"
    if (!FileExist(path "FanControl.exe"))
        return

    if (SubStr(cfg, -5) != ".json")
        cfg .= ".json"

    cfgPath := path "configurations\" cfg
    if (!FileExist(cfgPath)) {
        MsgBox("FanControl configuration not found: " cfg)
        return
    }

    try Run('"' path 'FanControl.exe" -c "' cfg '"')
}

; Win32 dark menu support (lexikos)
Win32MenuDarkMode(dark := true) {
    if (VerCompare(A_OSVersion, "10.0.18362") < 0)
        return

    uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
    if (!uxtheme)
        return

    SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
    FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
    if (SetPreferredAppMode && FlushMenuThemes) {
        DllCall(SetPreferredAppMode, "int", dark)
        DllCall(FlushMenuThemes)
    }
}
