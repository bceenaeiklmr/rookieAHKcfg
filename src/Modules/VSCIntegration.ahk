#Requires AutoHotkey v2.0

class VSC {
    static title := "Visual Studio Code ahk_exe Code.exe"
    static hwnds := Array()

    ; Executable path discovery
    static path {
        get {
            local possiblePaths, p
            if (this.HasOwnProp("__path"))
                return this.__path

            possiblePaths := [
                A_ProgramFiles "\Microsoft VS Code\Code.exe",
                A_AppData "\Local\Programs\Microsoft VS Code\Code.exe",
                StrReplace(A_AppData, "\Roaming") "\Local\Programs\Microsoft VS Code\Code.exe"
            ]

            for p in possiblePaths {
                if (FileExist(p))
                    return this.__path := p
            }
            return ""
        }
        set {
            if (FileExist(value))
                this.__path := value
        }
    }

    ; Open a new VS Code window instance cleanly via CLI
    static NewInstance(files*) {
        local cmd, resolved, f
        if (!this.path)
            return

        cmd := '"' this.path '" -n'
        for f in files {
            resolved := (f ~= "^([a-zA-Z]:|\\\\)") ? f : (A_ScriptDir "\" f)
            cmd .= ' "' resolved '"'
        }
        try Run(cmd)
    }

    ; Open files in current VS Code instance
    static OpenFiles(files*) {
        local f, resolved
        if (!this.path)
            return

        for f in files {
            resolved := (f ~= "^([a-zA-Z]:|\\\\)") ? f : (A_ScriptDir "\" f)
            if (FileExist(resolved))
                try Run('"' this.path '" -r "' resolved '"')
        }
    }

    ; Backup currently open project/file
    static Backup(dest := "") {
        local filePath, fileName, fileDir, fileExt, nameNoExt, dateStamp, ext, backupFile
        filePath := this.FilePath()
        if (!filePath || !FileExist(filePath))
            return

        SplitPath(filePath, &fileName, &fileDir, &fileExt, &nameNoExt)
        dateStamp := FormatTime(A_Now, "ddMMyy_HHmmss")
        ext := (fileExt != "") ? ("." fileExt) : ""

        if (!dest)
            dest := fileDir "\backup\" nameNoExt

        if (!DirExist(dest))
            DirCreate(dest)

        backupFile := dest "\" nameNoExt "_" dateStamp ext
        try FileCopy(filePath, backupFile, true)
    }

    ; Project / active file title
    static Project() {
        local title
        if !WinExist(this.title)
            return ""
        title := WinGetTitle(this.title)
        return StrSplit(title, " - ")[1]
    }

    ; Editor hotkeys
    static FileCreate() => this.HK("^n")
    static FileOpen() => this.HK("^o")
    static FileClose() => this.HK("^{F4}")
    static FileCloseAll() => this.HK("^k|^w")
    static FileSave() => this.HK("^s")
    static FileSaveAs() => this.HK("^+s")
    static FileSaveAll() => this.HK("^k|s")
    static FileOpenNext() => this.HK("^{Tab}")
    static FileOpenPrevious() => this.HK("^+{Tab}")
    static FileShowInExplorer() => this.HK("^k|r")
    static FileShowNewInstance() => this.HK("^k|o")
    static IndentText() => this.HK("+!f")
    static Fold(level := 2) => this.HK("^k|^" level)
    static UnfoldAll() => this.HK("^k|^j")
    static UnfoldComment() => this.HK("^k|^{NumpadDiv}")
    static FilePath() => this.HK("^k|p*")

    ; Execute key combinations
    static HK(keys) {
        local clip, k, v
        clip := (keys ~= "\*") ? 1 : 0
        keys := StrSplit(StrReplace(keys, "*"), "|")
        
        loop (clip ? 2 : 1) {
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

    static __New() {
        if (A_TitleMatchMode !== 2)
            SetTitleMatchMode(2)
        if WinExist(this.title)
            this.hwnds.Push(WinExist("A"))
    }
}
