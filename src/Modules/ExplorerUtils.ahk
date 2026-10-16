#Requires AutoHotkey v2.0

; Windows File Explorer Inspection Utilities
; Based on Explorer.ahk by iseahound (https://github.com/iseahound/Explorer.ahk)
; Credits: iseahound, Lexikos, TheCrether, mikeyww

ExplorerWin(i?)   => ExplorerActive(i?)[2]
ExplorerPath(i?)  => (filepaths := ExplorerPaths(i?), filepaths.has(1) ? filepaths[1] : "")
ExplorerBase(i?)  => ExplorerSplitPath(ExplorerPath(i?)).basename
ExplorerDrive(i?) => ExplorerSplitPath(ExplorerDir(i?)).drive
ExplorerDir(i?)   => ExplorerActive(i?)[1]
ExplorerName(i?)  => ExplorerSplitPath(ExplorerPath(i?)).filename
ExplorerExt(i?)   => ExplorerSplitPath(ExplorerPath(i?)).extension
ExplorerFile(i?)  => ((filepath := ExplorerPath(i?)) ? ExplorerSplitPath(filepath) : "")

; Returns active folder path if Explorer or Desktop is focused; otherwise user home directory
GetTargetWorkingDir() {
    local dir, home
    try {
        dir := ExplorerDir()
        if (dir != "" && DirExist(dir))
            return dir
    }
    home := EnvGet("USERPROFILE")
    return (home != "" && DirExist(home)) ? home : A_MyDocuments
}

; Launch Command Prompt (standard or elevated) in target folder
LaunchCmd(asAdmin := false) {
    local dir, prefix
    dir := GetTargetWorkingDir()
    prefix := asAdmin ? "*RunAs " : ""
    try Run(prefix 'cmd.exe /K cd /d "' dir '"', dir)
}

; Launch PowerShell (standard or elevated) in target folder
LaunchPowerShell(asAdmin := false) {
    local dir, prefix
    dir := GetTargetWorkingDir()
    prefix := asAdmin ? "*RunAs " : ""
    try Run(prefix 'powershell.exe -NoExit -Command "Set-Location -LiteralPath `"' dir '`""', dir)
}

ExplorerSplitPath(filepath) {
    local basename, directory, extension, filename, drive
    SplitPath filepath, &basename, &directory, &extension, &filename, &drive
    if (DirExist(filepath)) {
        filename := basename
        extension := ""
    }

    return {
        filepath: filepath,         quotedfilepath: '"' filepath '"',
        basename: basename,         quotedbasename: '"' basename '"',
        directory: directory,       quoteddirectory: '"' directory '"',
        extension: extension,       quotedextension: '"' extension '"',
        filename: filename,         quotedfilename: '"' filename '"',
        drive: drive,               quoteddrive: '"' drive '"'
    }
}

ExplorerActive(inactive := false) {
    local hwnd, window, filepath, WinExistOrActive
    if (hwnd := WinActive("ahk_class WorkerW"))
    || (hwnd := WinActive("ahk_class Progman"))
        return [A_Desktop, hwnd]

    WinExistOrActive := (inactive) ? WinExist : WinActive
    if (hwnd := WinExistOrActive("ahk_class ExploreWClass"))
    || (hwnd := WinExistOrActive("ahk_class CabinetWClass")) {
        try {
            window := ExplorerActiveTab(hwnd)
            filepath := Type(window.Document) == "ShellFolderView"
                ? window.Document.Folder.Self.Path
                : window.LocationURL
            return [filepath, window.hwnd]
        }
    }

    return ["", 0]
}

ExplorerActiveTab(hwnd) {
    local activeTab, IShellBrowser, GetWindow, thisTab, window
    try activeTab := ControlGetHwnd("ShellTabWindowClass1", hwnd) ; Windows 11 File Explorer
    catch
    try activeTab := ControlGetHwnd("TabWindowClass1", hwnd) ; IE / older tabbed explorer

    for window in ComObject("Shell.Application").Windows {
        if (window.hwnd != hwnd)
            continue
        if IsSet(activeTab) {
            static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"
            IShellBrowser := ComObjQuery(window, IID_IShellBrowser, IID_IShellBrowser)
            ComCall(GetWindow := 3, IShellBrowser, "uint*", &thisTab := 0)
            if (thisTab != activeTab)
                continue
        }
        return window
    }
    throw Error("Could not locate active tab in Explorer window.")
}

ExplorerPaths(inactive := false) {
    local hwnd, window, filepaths, WinExistOrActive, item
    filepaths := []
    WinExistOrActive := (inactive) ? WinExist : WinActive
    if (hwnd := WinExistOrActive("ahk_class ExploreWClass"))
    || (hwnd := WinExistOrActive("ahk_class CabinetWClass")) {
        try {
            window := ExplorerActiveTab(hwnd)
            for item in window.Document.SelectedItems
                filepaths.Push(item.Path)
        }
    }
    if (WinActive("ahk_class WorkerW") || WinActive("ahk_class Progman")) {
        try hwnd := ControlGetHwnd("SysListView321", "ahk_class Progman")
        hwnd := hwnd || ControlGetHwnd("SysListView321", "A")
        try {
            Loop Parse ListViewGetContent("Selected Col1", hwnd), "`n", "`r"
                filepaths.Push(A_Desktop "\" A_LoopField)
        }
    }
    return filepaths
}
