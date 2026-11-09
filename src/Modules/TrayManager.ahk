#Requires AutoHotkey v2.0

class TrayManager {

    ; Initialize the reshaped tray menu
    static Init() {
        local tray, toolsMenu, fanSub

        tray := A_TrayMenu
        tray.Delete()

        ; Primary Module Entry: Worktime Logger
        tray.Add("Worktime Logger", (*) => WorktimeLogger.Show())
        tray.Default := "Worktime Logger"

        tray.Add() ; Separator

        ; Quick File & Config Access
        tray.Add("Edit config.ini", (*) => this.OpenFile(A_ScriptDir "\config.ini"))
        tray.Add("Edit abbreviations.txt", (*) => this.OpenFile(this.GetAbbreviationsPath()))
        tray.Add("Hotkey Cheat Sheet`tWin+F1", (*) => DisplayHotkeys())

        tray.Add() ; Separator

        ; Desktop & Utilities
        tray.Add("Toggle Desktop Icons`tCtrl+Win+C", (*) => DesktopIcons(-1))

        ; Tools Submenu
        toolsMenu := Menu()
        toolsMenu.Add("Hide Desktop Icons (GUI)", (*) => Run(A_ScriptDir "/src/HideMyIcon/HideMyIcon_Gui.ahk"))
        toolsMenu.Add("Mouse Trail`tCtrl+Win+F2", (*) => MouseTrail.Toggle())
        toolsMenu.Add("Mouse Trail: Next Mode`tCtrl+Win+Alt+F2", (*) => MouseTrail.NextMode())
        if (W32menu.HasFanControl()) {
            fanSub := Menu()
            fanSub.Add("Silent",    (*) => FanControl("Silent"))
            fanSub.Add("Game",      (*) => FanControl("Game"))
            fanSub.Add("Benchmark", (*) => FanControl("Benchmark"))
            toolsMenu.Add("Fan Control", fanSub)
        }
        toolsMenu.Add("Window Spy", (*) => this.LaunchWindowSpy())
        tray.Add("Tools", toolsMenu)

        tray.Add() ; Separator

        ; Script Lifecycle
        tray.Add("Reload Script", (*) => Reload())
        tray.Add("Suspend Hotkeys", (ItemName, ItemPos, MyMenu) => this.ToggleSuspend(ItemName, MyMenu))
        tray.Add("Exit", (*) => ExitApp())

        ; Assign menu icons
        this.ApplyIcons(tray, toolsMenu)
    }

    ; Open a file if it exists
    static OpenFile(path) {
        if (FileExist(path))
            try Run(path)
    }

    ; Resolve active or example abbreviations path
    static GetAbbreviationsPath() {
        local userPath := A_ScriptDir "\abbreviations.txt"
        local examplePath := A_ScriptDir "\abbreviations.example.txt"
        return FileExist(userPath) ? userPath : examplePath
    }

    ; Locate and launch AutoHotkey Window Spy
    static LaunchWindowSpy() {
        local ahkDir, spyPath
        SplitPath(A_AhkPath, , &ahkDir)
        spyPath := ahkDir "\..\WindowSpy.ahk"
        if (!FileExist(spyPath))
            spyPath := ahkDir "\..\UX\WindowSpy.ahk"
        if (!FileExist(spyPath))
            spyPath := ahkDir "\WindowSpy.ahk"

        if (FileExist(spyPath))
            try Run('"' A_AhkPath '" "' spyPath '"')
    }

    ; Toggle hotkey suspension and sync checkmark
    static ToggleSuspend(itemName, menuObj) {
        Suspend(-1)
        if (A_IsSuspended)
            menuObj.Check(itemName)
        else
            menuObj.Uncheck(itemName)
    }

    ; Apply shell and system icons to menu items
    static ApplyIcons(tray, toolsMenu) {
        try {
            tray.SetIcon("Worktime Logger", "shell32.dll", 239)
            tray.SetIcon("Edit config.ini", "shell32.dll", 70)
            tray.SetIcon("Edit abbreviations.txt", "shell32.dll", 260)
            tray.SetIcon("Hotkey Cheat Sheet`tWin+F1", "shell32.dll", 24)
            tray.SetIcon("Toggle Desktop Icons`tCtrl+Win+C", "shell32.dll", 35)
            tray.SetIcon("Tools", "shell32.dll", 37)
            tray.SetIcon("Reload Script", "shell32.dll", 239)
            tray.SetIcon("Suspend Hotkeys", "shell32.dll", 110)
            tray.SetIcon("Exit", "shell32.dll", 132)

            toolsMenu.SetIcon("Hide Desktop Icons (GUI)", "shell32.dll", 70)
            toolsMenu.SetIcon("Mouse Trail`tCtrl+Win+F2", "main.cpl", 1)
            toolsMenu.SetIcon("Mouse Trail: Next Mode`tCtrl+Win+Alt+F2", "shell32.dll", 239)
            if (W32menu.HasFanControl())
                toolsMenu.SetIcon("Fan Control", "shell32.dll", 13)
            toolsMenu.SetIcon("Window Spy", "shell32.dll", 23)
        }
    }
}
