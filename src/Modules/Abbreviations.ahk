#Requires AutoHotkey v2.0

; Expand company/project abbreviations in text
TranslateAbbreviations(str) {
    local seen, out, pos, m, key, val, line
    local dictPath, examplePath, dir, f, keys, escapedKeys, tmp

    static abbreviations := Map()
    static pattern := ""

    SplitPath(A_LineFile,, &dir)
    dictPath := dir "\..\..\abbreviations.txt"
    examplePath := dir "\..\..\abbreviations.example.txt"
    if (!FileExist(dictPath) && FileExist(examplePath)) {
        try FileCopy(examplePath, dictPath)
    }
    if (!FileExist(dictPath))
        dictPath := A_ScriptDir "\abbreviations.txt"
    if (!FileExist(dictPath))
        return str

    if (!pattern) {
        keys := []
        f := FileRead(dictPath, "UTF-8")
        f := StrReplace(f, "`r`n", "`n")

        for line in StrSplit(f, "`n") {
            line := Trim(line)
            if (!line || SubStr(line, 1, 1) == ";")
                continue

            parts := StrSplit(line, "`t")
            if (parts.Length < 2)
                continue

            key := Trim(parts[1])
            val := Trim(parts[2])

            abbreviations[key] := val
            keys.Push(key)
        }

        if (keys.Length == 0)
            return str

        ; Sort longest first so compound abbreviations match before substrings
        Loop keys.Length - 1 {
            Loop keys.Length - A_Index {
                if (StrLen(keys[A_Index]) < StrLen(keys[A_Index + 1])) {
                    tmp := keys[A_Index]
                    keys[A_Index] := keys[A_Index + 1]
                    keys[A_Index + 1] := tmp
                }
            }
        }

        escapedKeys := []
        for key in keys
            escapedKeys.Push(RegExEscape(key))

        pattern := "(?<![\pL\pN_])(" Join("|", escapedKeys) ")(?![\pL\pN_])"
    }

    seen := Map()
    out := ""
    pos := 1

    while RegExMatch(str, pattern, &m, pos) {
        out .= SubStr(str, pos, m.Pos - pos)
        key := m[1]
        val := abbreviations[key]

        if (seen.Has(key) || AlreadyExpanded(str, m.Pos, m.Len, key, val)) {
            seen[key] := true
            out .= key
        } else {
            seen[key] := true
            out .= key " (" val ")"
        }

        pos := m.Pos + m.Len
    }

    out .= SubStr(str, pos)
    return out
}

; Check if an abbreviation is already accompanied by its expansion
AlreadyExpanded(text, pos, len, key, value) {
    local before, after
    before := SubStr(text, Max(1, pos - StrLen(value) - 3), StrLen(value) + 3)
    if (RegExMatch(before, RegExEscape(value) "\s*\($"))
        return true

    after := SubStr(text, pos + len)
    if (RegExMatch(after, "^\s*\(\s*" RegExEscape(value) "\s*\)"))
        return true

    return false
}

Join(sep, arr) {
    local out, i, v
    out := ""
    for i, v in arr
        out .= (i > 1 ? sep : "") v
    return out
}

RegExEscape(str) => RegExReplace(str, "([\\.^$|?*+()[\]{}])", "\$1")
