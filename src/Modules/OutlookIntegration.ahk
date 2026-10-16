#Requires AutoHotkey v2.0

; Toggle read/unread state of selected Outlook items via COM
OutlookToggleReadState() {
    local Outlook, explorer, mail

    try {
        Outlook := ComObjActive("Outlook.Application")
    } catch {
        try {
            Outlook := ComObject("Outlook.Application")
        } catch {
            return false
        }
    }

    if (!Outlook is ComValue)
        return false

    try {
        if (!explorer := Outlook.ActiveExplorer())
            return false

        if ((!selection := explorer.Selection) || selection.Count == 0)
            return false

        static olMailClass := 43
        static olTaskRequestAccept := 51
        static olMeetingResponseTentative := 57

        for mail in selection {
            try {
                if (mail.Class == olMailClass
                 || (mail.Class >= olTaskRequestAccept && mail.Class < olMeetingResponseTentative)) {
                    mail.UnRead := !mail.UnRead
                }
            }
        }
        return true
    } catch {
        return false
    }
}
