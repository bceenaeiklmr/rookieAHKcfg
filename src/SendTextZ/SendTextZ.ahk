; Script     SendTextZ.ahk
; License:   MIT License
; Author:    Bence Markiel (bceenaeiklmr)
; Github:    https://github.com/bceenaeiklmr/SendTextZ
; Date       06.04.2025
; Version    0.3.0

SendTextZ

SendTextZ(triggerHotkey := ":") {

    ; Main menu.
    texts := Menu()

    ; Read INI file.
    fileName := A_ScriptDir "\src\SendTextZ\hotstring.ini"
    sections := IniRead(fileName)

    ; Read sections and create section menus.
    for section in StrSplit(sections, "`n") {
        sectMenu := Menu()
       
        ; Read keys from section.
        keys := IniRead(fileName, section)
        keys := StrSplit(keys, "`n")
        for key in keys {
            
            ; Temporarily replace OR with a different character.
            if InStr(key, "||")
                key := StrReplace(key, "||", "Ͻ")
            
            key := StrSplit(key, "|")
            for v in key
                key[A_index] := Trim(v)
            
            ; Make `n chars visible in menus.
            if (key.Length = 4 && InStr(key[4], "``n")) 
                key[4] := StrReplace(key[4], "``n", "`n")
            
            ; Replace temporary character.
            if InStr(key[3], "Ͻ")
                key[3] := StrReplace(key[3], "Ͻ", "||")

            pre := key[1]
            txt := key[3]
            str := (key.Length < 4) ? key[3] : key[4]

            sectMenu.Add(pre "`t" txt, SendStr.Bind(str))

            ; Create hotstring.
            for hotStr in StrSplit(key[2], ",") {
                HotString(":*:" triggerHotkey Trim(hotStr), SendStr.Bind(str))
            }

            texts.Add(section, sectMenu)
        }        
    }

    W32menu.main.Add("Texts", texts)
    W32menu.main.SetIcon("Texts", "Shell32.dll", 75)
}

SendStr(str, *) {
    if (SubStr(str, 1, 1) == "*") {
        return Send(SubStr(str, 2))
    }
    SendText(str)
    return
}
