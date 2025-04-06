; Script     SendTextZ.ahk
; License:   MIT License
; Author:    Bence Markiel (bceenaeiklmr)
; Github:    https://github.com/bceenaeiklmr/SendTextZ
; Date       19.05.2024
; Version    0.2.2

#include ../../rookieAHKcfg.ahk

SendTextZ()

; TODO: Refactor old code
; TODO: IniRead works but only with UTF-16 files
; FileEncoding("UTF-16")
; inp := IniRead("C:\Dev\ahk\GitHub\ahkCFG\src\sendTextZ\hotstring - Copy.ini", "Emoji Faces")

SendTextZ(TriggerHotkey := ":") {

    ; IniRead only supports Unicode in UTF-16 files.
    Input := FileRead(A_ScriptDir "\src\SendTextZ\hotstring.ini")
    ; temporarily replace OR
    InputFile := StrReplace(Input, "||", "Ͻ")
    Sect := Array()
    loop Parse, InputFile, "`n" {
        ; skip empty and comment lines
        if (A_LoopField ~= "^;") || (3 > StrLen(A_LoopField))
            continue
        Line := StrReplace(A_LoopField, Chr(13))
        ; category names
        if RegExMatch(Line, "^\[\w+(\s\w+)*\]", &Lines) {    ; regex
            Name := Trim(SubStr(Lines[], 2, -1))
            Sect.Push({ Name: Name, Hotkeys: [] })
        }
        else { ; hotkeys
            ; columns are separated by the pipe '|' chr
            Col := StrSplit(Line, "|")
            for v in Col {
                Col[A_index] := Trim(v)
                ; make `n chars visible in menus
                if (A_index = 4)
                    Col[A_index] := StrReplace(v, '``n', '`n')
                if InStr(v, "Ͻ")
                    Col[A_index] := StrReplace(v, "Ͻ", "||")
            }

            obj := { Preview : Col[1]
                   , Hotstrg : Col[2]
                   , Text    : Col[3]
                   , Code    : (4 > Col.length) ? "" : Col[4] }

            Sect[Sect.Length].Hotkeys.Push(obj)
        }
    }

    ; create menus
    Texts := Menu()
    for v in Sect {
        SectMenu := Menu()
        for hk in v.Hotkeys {
            vStrg := Trim((hk.Code !== "") ? hk.Code : hk.Text)
            Sectmenu.Add(hk.Preview "`t" hk.Text, SendStr.Bind(vStrg))
            ; register hotstrings
            hStrings := StrSplit(hk.HotStrg, ",")
            for hStr in hStrings
                HotString(":*:" TriggerHotkey Trim(hStr), SendStr.Bind(vStrg))            
        }
        texts.Add(v.Name, sectmenu)
    }

    W32menu.main.Add("Texts", texts)
    W32menu.main.SetIcon('Texts', 'Shell32.dll', 75)
    return
}

SendStr(str, *) {
    if (SubStr(str, 1, 1) == '*') {
        return Send(SubStr(str, 2))
    }
    cb := ClipboardAll()
    A_Clipboard := str
    if ClipWait(.4, 0) {
        Send("{CtrlDown}v{CtrlUp}")
        Sleep(100)
    }
    A_Clipboard := cb
    return
}
