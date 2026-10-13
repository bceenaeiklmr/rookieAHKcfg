#Requires AutoHotkey v2.0

; Global variables populated by ConfigManager
global devFolderPath := "C:\dev"
global devPrivateLib := "C:\dev\ahk\private"

; Load configuration from config.ini safely with defaults
LoadConfig() {
    global devFolderPath, devPrivateLib
    cfgFile := A_ScriptDir "\config.ini"

    if (FileExist(cfgFile)) {
        devFolderPath := IniRead(cfgFile, "Settings", "devFolderPath", "C:\dev")
        devPrivateLib := IniRead(cfgFile, "Settings", "devPrivateLib", "C:\dev\ahk\private")
        startupAsked := Integer(IniRead(cfgFile, "Settings", "StartupAsked", "0"))
        
        ; If startup wasn't configured yet, prompt once
        if (!startupAsked) {
            ScriptToStartup()
            IniWrite(1, cfgFile, "Settings", "StartupAsked")
        }
    }
    else {
        devFolderPath := "C:\"
        devPrivateLib := "C:\dev"
        
        MsgBox("Config file created, it will be opened after pressing OK.`n`n"
            "Please set your variables.`n`n"
            "( you can skip this step, and this message will not appear again )"
            , "rookieAHKcfg - missing config file", 0x40)

        IniWrite(devFolderPath, cfgFile, "Settings", "devFolderPath")
        IniWrite(devPrivateLib, cfgFile, "Settings", "devPrivateLib")
        IniWrite(1, cfgFile, "Settings", "StartupAsked")
        
        ScriptToStartup()
        try Run(cfgFile)
    }
    return
}

; Add/delete the current script to/from the Windows Startup folder
ScriptToStartup(allUser := false, delete := false) {
    folder := (!allUser) ? A_Startup : A_StartupCommon

    SplitPath(A_ScriptName,,,, &baseName)
    linkFile := folder "\" baseName ".lnk"

    if (delete) {
        if (FileExist(linkFile)) {
            FileDelete(linkFile)
            MsgBox("Script removed from startup folder.", baseName, 0x40)
        }
        return
    }

    if (!FileExist(linkFile)) {
        result := MsgBox("Would you like to add rookieAHKcfg to Windows Startup?`n`n"
            "( Recommended for daily use )`n`n"
            "You can always add or remove it later from the menu.", baseName, 0x24)

        if (result == "Yes") {
            target := A_ScriptFullPath
            FileCreateShortcut(target, linkFile, A_ScriptDir)
            MsgBox("Script added to startup folder.", baseName, 0x40 " T1")
        }
    }
    return
}
