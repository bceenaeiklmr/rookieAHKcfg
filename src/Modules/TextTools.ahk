#Requires AutoHotkey v2.0

; Copy selected text to clipboard and return it
ClipboardGetText(restore := 1, timeout := .4) {
    local c := "", cbSaved

    if (restore)
        cbSaved := ClipboardAll()

    A_Clipboard := ""
    Sleep(20)
    Send("{CtrlDown}c{CtrlUp}")
    if (ClipWait(timeout, 0))
        c := A_Clipboard

    if (restore)
        A_Clipboard := cbSaved

    return c
}

; Paste a string from the clipboard, restore content, auto reselect
ClipboardPaste(str, restore := true, reselect := false) {
    local cbSaved := ClipboardAll()

    A_Clipboard := str
    Send("{CtrlDown}v{CtrlUp}")
    Sleep(150)

    if (reselect)
        Send("{ShiftDown}{Left " StrLen(str) "}{ShiftUp}")

    if (restore)
        SetTimer(() => A_Clipboard := cbSaved, -100)

    return
}

; Copy selected text to clipboard and call transformation function with it
StrWin32MenuCopy(fn, params*) {
    local cbSaved := ClipboardAll()

    A_Clipboard := ""
    Send("{CtrlDown}c{CtrlUp}")
    if (ClipWait(.3, 0)) {
        input := A_Clipboard
        params.InsertAt(1, input)
        result := (%fn%)(params*)
        A_Clipboard := result
        Send("{CtrlDown}v{CtrlUp}")
        Sleep(150)
    }

    SetTimer(() => A_Clipboard := cbSaved, -100)
    return
}

; Lowercase
StrLower(str) => Format("{:L}", str)

; Uppercase
StrUpper(str) => Format("{:U}", str)

; Titlecase
StrTitle(str) => Format("{:T}", str)

; Random case
StrRandom(str) {
    local s := ""
    Loop Parse, str
        s .= Format("{:" (Random(0, 1) ? "U" : "L") "}", A_LoopField)
    return s
}

; Invert case: uppercase becomes lowercase and vice-versa
StrInverse(str) {
    local s := "", f
    Loop Parse, str {
        f := A_LoopField
        s .= (f == Format("{:U}", f)) ? Format("{:L}", f) : Format("{:U}", f)
    }
    return s
}

; Reverse string
StrReverse(input) {
    local str := ""
    Loop Parse, input
        str .= SubStr(input, StrLen(input) - A_Index + 1, 1)
    return str
}

; Add right padding
StrLenghten(str, len, char := " ") {
    loop Max(0, len - StrLen(str))
        str .= char
    return str
}

; Remove empty lines and trailing newline
StrReplaceEmptyLines(str) {
    str := StrReplace(str, "`r`n", "`n")
    while InStr(str, "`n`n")
        str := StrReplace(str, "`n`n", "`n")
    if (SubStr(str, -1) == "`n")
        str := SubStr(str, 1, -1)
    return str
}

; Align a string by the given delimiter safely without crashing on uneven lines
StrAlign(str, delimRow := "`n", delimCol := "|") {
    str := StrReplaceEmptyLines(str)
    text := []
    maxCols := 0

    loop parse str, delimRow {
        if (A_LoopField ~= "\d|\w") {
            line := StrSplit(A_LoopField, delimCol)
            for i, c in line
                line[i] := Trim(c)
            if (line.Length > maxCols)
                maxCols := line.Length
            text.Push(line)
        }
    }

    if (text.Length == 0)
        return str

    ; Initialize lengths up to maxCols
    lengths := []
    loop maxCols
        lengths.Push(0)

    for line in text {
        for i, col in line {
            if (StrLen(col) > lengths[i])
                lengths[i] := StrLen(col)
        }
    }

    ret := ""
    for line in text {
        for i, col in line {
            align := (i !== line.Length) ? 1 : 0
            ret .= (align ? StrLenghten(col, lengths[i]) : col)
                .  (align ? " " delimCol " " : "`n")
        }
    }
    return SubStr(ret, 1, -1)
}

; Wrap/unwrap selected text with specified delimiter characters
StrWrap(char, filler := "") {
    cbSaved := ClipboardAll()

    A_Clipboard := ""
    Send("{CtrlDown}c{CtrlUp}")
    cb := (ClipWait(0.2)) ? A_Clipboard : ""

    chars := StrSplit(char)
    leftChar  := chars[1]
    rightChar := (chars.Length > 1) ? chars[2] : chars[1]

    leftWrap  := leftChar . filler
    rightWrap := filler . rightChar

    leftLen  := StrLen(leftWrap)
    rightLen := StrLen(rightWrap)
    cbLen    := StrLen(cb)

    isWrapped := (cbLen >= leftLen + rightLen)
        && (SubStr(cb, 1, leftLen) == leftWrap)
        && (SubStr(cb, -rightLen) == rightWrap)

    if (isWrapped)
        outStr := SubStr(cb, leftLen + 1, cbLen - leftLen - rightLen)
    else
        outStr := leftWrap . cb . rightWrap

    ; Output text
    if (StrLen(outStr) > 40) {
        A_Clipboard := outStr
        Send("{CtrlDown}v{CtrlUp}")
        Sleep(100)
    } else {
        SendText(outStr)
    }

    ; Handle selection and caret positioning
    if (cbLen == 0) {
        Send("{Left " . rightLen . "}")
    } else if ((outLen := StrLen(outStr)) > 0) {
        Send("{Left " . outLen . "}")
        Send("{ShiftDown}{Right " . outLen . "}{ShiftUp}")
    }

    ; Always restore clipboard asynchronously
    SetTimer(() => A_Clipboard := cbSaved, -150)
    return
}

; Format and word-wrap comment blocks
StrFormatComment(text, maxLen := 80) {
    if (Trim(text) == "")
        return text

    prefix := ""
    if RegExMatch(text, "^\s*([#;/]+)", &match) {
        prefix := match[1] . A_Space
        text := RegExReplace(text, "^\s*[#;/]+\s*", "")
    }

    text := RegExReplace(text, "\s+", A_Space)
    text := Trim(text)

    words := StrSplit(text, A_Space)
    result := ""
    currentLine := ""

    for _, word in words {
        testLine := (currentLine == "") ? word : currentLine . A_Space . word
        if (StrLen(prefix . testLine) <= maxLen) {
            currentLine := testLine
        } else {
            if (result !== "")
                result .= "`n"
            result .= prefix . currentLine
            currentLine := word
        }
    }

    if (currentLine !== "") {
        if (result !== "")
            result .= "`n"
        result .= prefix . currentLine
    }

    return result
}

; Split identifiers or phrases into word tokens for casing conversions
StrExtractWords(str) {
    ; Insert space before uppercase letters in camelCase/PascalCase
    s := RegExReplace(str, "([a-z\d])([A-Z])", "$1 $2")
    ; Replace delimiters with spaces
    s := RegExReplace(s, "[_\-\s]+", " ")
    s := Trim(s)
    words := []
    for w in StrSplit(s, " ") {
        if (w != "")
            words.Push(Format("{:L}", w))
    }
    return words
}

; camelCase
StrCamelCase(str) {
    words := StrExtractWords(str)
    if (words.Length == 0)
        return str
    res := words[1]
    loop words.Length - 1 {
        res .= Format("{:T}", words[A_Index + 1])
    }
    return res
}

; PascalCase
StrPascalCase(str) {
    words := StrExtractWords(str)
    res := ""
    for w in words
        res .= Format("{:T}", w)
    return (res != "") ? res : str
}

; snake_case
StrSnakeCase(str) {
    words := StrExtractWords(str)
    res := ""
    for i, w in words
        res .= (i > 1 ? "_" : "") w
    return (res != "") ? res : str
}

; SCREAMING_SNAKE_CASE
StrScreamingSnake(str) => Format("{:U}", StrSnakeCase(str))

; kebab-case
StrKebabCase(str) {
    words := StrExtractWords(str)
    res := ""
    for i, w in words
        res .= (i > 1 ? "-" : "") w
    return (res != "") ? res : str
}

; Path formatters
StrPathSlash(str) => StrReplace(str, "\", "/")
StrPathBackslash(str) => StrReplace(str, "/", "\")
StrPathEscaped(str) => StrReplace(StrReplace(str, "/", "\"), "\", "\\")

; Return current date and time
DateNow(fmt := "dd.MM.yy. HH:mm:ss") => FormatTime(A_Now, fmt)
