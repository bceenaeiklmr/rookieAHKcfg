#Requires AutoHotkey v2.0

; RFC-3986 compliant UTF-8 URL percent encoder
UriEncode(str) {
    if (str == "")
        return ""

    buf := Buffer(StrPut(str, "UTF-8"))
    StrPut(str, buf, "UTF-8")
    res := ""
    
    loop buf.Size - 1 {
        byte := NumGet(buf, A_Index - 1, "UChar")
        ; Unreserved characters: A-Z a-z 0-9 - _ . ~
        if ((byte >= 0x30 && byte <= 0x39)
         || (byte >= 0x41 && byte <= 0x5A)
         || (byte >= 0x61 && byte <= 0x7A)
         || byte == 0x2D || byte == 0x2E || byte == 0x5F || byte == 0x7E) {
            res .= Chr(byte)
        } else {
            res .= "%" Format("{:02X}", byte)
        }
    }
    return res
}

; Check if a string looks like a web URL
IsURL(str) {
    s := Trim(str)
    if RegExMatch(s, "i)^(https?|ftp|file)://")
        return true
    if RegExMatch(s, "i)^www\.[a-z0-9\-]+\.[a-z]{2,}")
        return true
    if RegExMatch(s, "i)^[a-z0-9\-]+(\.[a-z0-9\-]+)*\.(com|org|net|io|edu|gov|hu|de|uk|eu|dev|app|ai|me)(/.*)?$")
        return true
    return false
}

; Normalize URL with https scheme if missing
NormalizeURL(str) {
    s := Trim(str)
    if !RegExMatch(s, "i)^[a-z0-9+\.\-]+://")
        s := "https://" . s
    return s
}

; Search selected text in Google, or directly open if it's a URL
SearchSelectedText(save := true) {
    cb := Trim(ClipboardGetText(, 0.25))
    if (cb == "")
        return

    ; If selected text is a URL, open it directly in default browser
    if (IsURL(cb)) {
        try Run(NormalizeURL(cb))
        return
    }

    ; Otherwise search via Google with safe URI encoding
    url := "https://www.google.com/search?q=" UriEncode(cb)
    try Run(url)

    if (save) {
        logLine := Format("{:02}.{:02}.{:02} {:02}:{:02}:{:02}`t{}"
            , A_DD, A_MM, SubStr(A_YYYY, 3, 2), A_Hour, A_Min, A_Sec, cb)
        try FileAppend(logLine "`n", A_MyDocuments "\google_stats.txt", "UTF-8")
    }
}

; Translate selected text with Google Translate
TranslateWeb(languageDisplay := "en", languageSource := "auto", languageTarget := "auto") {
    cb := Trim(ClipboardGetText(, 0.25))
    if (cb == "")
        return

    params := "?hl=" languageDisplay
        . "&eotf=0"
        . "&sl=" languageSource
        . "&tl=" languageTarget
        . "&text=" UriEncode(cb)
        . "&op=translate"

    try Run("https://translate.google.com/" params)
}

; Open ChatGPT with selected text as pre-filled prompt query
GptSelectedText(save := true) {
    cb := Trim(ClipboardGetText(, 0.25))
    if (cb == "")
        return

    ; Use ChatGPT query parameter for instant, reliable prompt population
    try Run("https://chatgpt.com/?q=" UriEncode(cb))

    if (save) {
        logLine := Format("{:02}.{:02}.{:02} {:02}:{:02}:{:02}`t{}"
            , A_DD, A_MM, SubStr(A_YYYY, 3, 2), A_Hour, A_Min, A_Sec, cb)
        try FileAppend(logLine "`n", A_MyDocuments "\gpt_stats.txt", "UTF-8")
    }
}
