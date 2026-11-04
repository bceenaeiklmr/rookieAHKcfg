#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; Worktime Logger (AutoHotkey v2)
; Author: Bence Markiel
; Description: Daily worktime logger, tracker, and statistics dashboard.
; Schedule: Mon-Thu 08:00-16:40 (8h 20m net), Fri 08:00-15:00 (6h 40m net).
; Lunch break: 20 minutes daily. Standard weekly target: 40h 00m.
; Storage: worktime.csv
; ==============================================================================

class WorktimeLogger {
    static csvPath := ""
    static data := Map()
    static gui := ""

    ; Control references
    static dtControl := ""
    static ddlMissing := ""
    static edStart := ""
    static edEnd := ""
    static edLunch := ""
    static chkHomeOffice := ""
    static edNote := ""
    static txtDayStatus := ""
    static lvStats := ""
    static sb := ""
    static missingDlg := ""

    ; Initialize paths and storage
    static Init() {
        if (this.csvPath == "") {
            SplitPath(A_LineFile, , &dir)
            this.csvPath := dir "\worktime.csv"
        }
        if (!FileExist(this.csvPath)) {
            f := FileOpen(this.csvPath, "w", "UTF-8")
            f.Write("Date,Start,End,Lunch,HomeOffice,Note`n")
            f.Close()
        }
        this.LoadData()
    }

    ; Show GUI
    static Show() {
        this.Init()

        if (this.gui != "") {
            try {
                this.gui.Show()
                this.SetToday()
                return
            } catch {
                this.gui := ""
            }
        }

        g := Gui("+Resize +MinSize600x570", "Worktime Logger")
        this.gui := g
        g.SetFont("s10", "Segoe UI")

        ; --- Date Navigation ---
        g.Add("Text", "xm y15 w45", "Date:")
        this.dtControl := g.Add("DateTime", "x+5 yp-3 w165", "yyyy-MM-dd (ddd)")
        this.dtControl.OnEvent("Change", (*) => this.OnDateChanged())

        btnPrev := g.Add("Button", "x+5 yp-1 w32 h26", "◄")
        btnPrev.ToolTip := "Previous day"
        btnPrev.OnEvent("Click", (*) => this.ChangeDateOffset(-1))

        btnToday := g.Add("Button", "x+4 yp w55 h26", "Today")
        btnToday.ToolTip := "Jump to today"
        btnToday.OnEvent("Click", (*) => this.SetToday())

        btnNext := g.Add("Button", "x+4 yp w32 h26", "►")
        btnNext.ToolTip := "Next day"
        btnNext.OnEvent("Click", (*) => this.ChangeDateOffset(1))

        this.ddlMissing := g.Add("DropDownList", "x+15 yp w185", ["✔ All past days logged"])
        this.ddlMissing.ToolTip := "Missing or incomplete workdays. Select to jump directly to that date."
        this.ddlMissing.OnEvent("Change", (*) => this.OnMissingSelected())

        btnCheckMissing := g.Add("Button", "x+4 yp w36 h26", "🔍")
        btnCheckMissing.ToolTip := "Check all missing / incomplete workdays (Scope: month, since first entry, etc.)"
        btnCheckMissing.OnEvent("Click", (*) => this.ShowMissingDialog())

        ; --- Work Hours Inputs ---
        g.Add("Text", "xm y+16 w55", "Start:")
        this.edStart := g.Add("Edit", "x+5 yp-3 w75", "")
        this.edStart.OnEvent("Change", (*) => this.UpdateLiveStatus())

        btnStartNow := g.Add("Button", "x+5 yp-1 w85 h26", "Start Now")
        btnStartNow.ToolTip := "Set start time to current time"
        btnStartNow.OnEvent("Click", (*) => this.SetCurrentTime(this.edStart))

        g.Add("Text", "x+20 yp+1 w45", "End:")
        this.edEnd := g.Add("Edit", "x+5 yp-3 w75", "")
        this.edEnd.OnEvent("Change", (*) => this.UpdateLiveStatus())

        btnEndNow := g.Add("Button", "x+5 yp-1 w85 h26", "End Now")
        btnEndNow.ToolTip := "Set end time to current time"
        btnEndNow.OnEvent("Click", (*) => this.SetCurrentTime(this.edEnd))

        ; Lunch, Home Office & Note
        g.Add("Text", "xm y+14 w55", "Lunch:")
        this.edLunch := g.Add("Edit", "x+5 yp-3 w75 Number", "20")
        this.edLunch.ToolTip := "Lunch break duration in minutes (default 20)"
        this.edLunch.OnEvent("Change", (*) => this.UpdateLiveStatus())

        btnDefault := g.Add("Button", "x+5 yp-1 w85 h26", "Fill Default")
        btnDefault.ToolTip := "Fill default schedule (Mon-Thu 08:00-16:40, Fri 08:00-15:00)"
        btnDefault.OnEvent("Click", (*) => this.FillDefaults())

        this.chkHomeOffice := g.Add("CheckBox", "x+18 yp+3 w110", "Home office")
        this.chkHomeOffice.ToolTip := "Mark this workday as Home Office"
        this.chkHomeOffice.OnEvent("Click", (*) => this.UpdateLiveStatus())

        g.Add("Text", "x+10 yp-3 w45", "Note:")
        this.edNote := g.Add("Edit", "x+5 yp-3 w145", "")
        this.edNote.ToolTip := "Optional note (e.g. Doctor, Sick leave)"

        ; --- Action Buttons ---
        btnSave := g.Add("Button", "xm y+15 w125 h30 Default", "💾 Save Entry")
        btnSave.ToolTip := "Save entry to CSV (Enter / Ctrl+S)"
        btnSave.OnEvent("Click", (*) => this.SaveCurrentEntry())

        btnDelete := g.Add("Button", "x+10 yp w105 h30", "🗑 Delete")
        btnDelete.ToolTip := "Delete entry for selected date"
        btnDelete.OnEvent("Click", (*) => this.DeleteCurrentEntry())

        btnOpenCsv := g.Add("Button", "x+10 yp w115 h30", "📂 Open CSV")
        btnOpenCsv.ToolTip := "Open worktime.csv in default application (Excel / Notepad)"
        btnOpenCsv.OnEvent("Click", (*) => this.OpenCsv())

        btnRefresh := g.Add("Button", "x+10 yp w105 h30", "🔄 Refresh")
        btnRefresh.ToolTip := "Refresh calculations and reload from file"
        btnRefresh.OnEvent("Click", (*) => this.RefreshAll())

        ; --- Day Status Panel ---
        g.Add("GroupBox", "xm y+15 w576 h70", "Day Plan & Status")
        this.txtDayStatus := g.Add("Text", "xp+12 yp+22 w552 r2", "")

        ; --- Statistics Panel ---
        g.Add("GroupBox", "xm y+12 w576 h185", "Statistics & Plan Balance")
        this.lvStats := g.Add("ListView", "xp+10 yp+22 w556 h150 -Multi +Grid", ["Period", "Worked", "Target", "Balance", "Remaining"])
        this.lvStats.ModifyCol(1, 105)
        this.lvStats.ModifyCol(2, 90)
        this.lvStats.ModifyCol(3, 180)
        this.lvStats.ModifyCol(4, 90)
        this.lvStats.ModifyCol(5, 90)

        ; --- Status Bar ---
        this.sb := g.Add("StatusBar")
        this.sb.SetText("Ready.")

        ; Window events
        g.OnEvent("Close", (*) => this.OnWindowClose())
        g.OnEvent("Escape", (*) => this.OnWindowClose())

        ; Initial load
        this.SetToday()

        ; Periodic timer to keep live status updated every minute
        SetTimer(() => this.OnTimerTick(), 60000)

        g.Show("w600")
    }

    static OnWindowClose() {
        if (A_LineFile == A_ScriptFullPath)
            ExitApp()
        else
            this.gui.Hide()
    }

    ; Jump to today
    static SetToday() {
        this.dtControl.Value := FormatTime(A_Now, "yyyyMMdd")
        this.OnDateChanged()
    }

    ; Offset date by N days
    static ChangeDateOffset(days) {
        currentVal := this.dtControl.Value
        newVal := DateAdd(currentVal, days, "days")
        this.dtControl.Value := newVal
        this.OnDateChanged()
    }

    ; Fill current time HH:mm
    static SetCurrentTime(control) {
        control.Value := FormatTime(A_Now, "HH:mm")
        this.UpdateLiveStatus()
    }

    ; Fill default schedule
    static FillDefaults() {
        dateStr := this.GetSelectedDateStr()
        clean := StrReplace(dateStr, "-")
        wday := Integer(FormatTime(clean, "WDay")) ; 1=Sun, 2=Mon... 6=Fri, 7=Sat

        this.edStart.Value := "08:00"
        this.edLunch.Value := "20"

        if (wday >= 2 && wday <= 5) {
            this.edEnd.Value := "16:40"
        } else if (wday == 6) {
            this.edEnd.Value := "15:00"
        } else {
            this.edEnd.Value := "12:00"
            this.edLunch.Value := "0"
        }
        this.UpdateLiveStatus()
    }

    ; When date selection changes
    static OnDateChanged() {
        dateStr := this.GetSelectedDateStr()
        if (this.data.Has(dateStr)) {
            entry := this.data[dateStr]
            this.edStart.Value := entry.start
            this.edEnd.Value := entry.end
            this.edLunch.Value := entry.lunch
            this.chkHomeOffice.Value := (entry.HasProp("ho") && entry.ho) ? 1 : 0
            this.edNote.Value := entry.note
        } else {
            isToday := (dateStr == FormatTime(A_Now, "yyyy-MM-dd"))
            this.edStart.Value := isToday ? "08:00" : ""
            this.edEnd.Value := ""
            this.edLunch.Value := "20"
            this.chkHomeOffice.Value := 0
            this.edNote.Value := ""
        }
        this.RefreshAll()
    }

    ; Save current entry
    static SaveCurrentEntry() {
        dateStr := this.GetSelectedDateStr()
        startVal := Trim(this.edStart.Value)
        endVal := Trim(this.edEnd.Value)
        lunchVal := Trim(this.edLunch.Value)
        noteVal := Trim(this.edNote.Value)

        ; Validate Start time
        if (startVal != "" && this.ParseTimeToMinutes(startVal) < 0) {
            MsgBox("Invalid start time format! Please use HH:mm (e.g. 08:00).", "Validation Error", "Icon!")
            return
        }

        ; Validate End time
        if (endVal != "" && this.ParseTimeToMinutes(endVal) < 0) {
            MsgBox("Invalid end time format! Please use HH:mm (e.g. 16:40).", "Validation Error", "Icon!")
            return
        }

        noteVal := StrReplace(noteVal, ",", ";")
        lunchMins := (lunchVal == "" || !IsInteger(lunchVal)) ? 20 : Integer(lunchVal)

        this.data[dateStr] := {
            date: dateStr,
            start: startVal,
            end: endVal,
            lunch: lunchMins,
            ho: this.chkHomeOffice.Value ? 1 : 0,
            note: noteVal
        }

        this.SaveData()
        this.RefreshAll()
        this.sb.SetText("Saved entry for " . dateStr . " at " . FormatTime(A_Now, "HH:mm:ss"))
    }

    ; Delete entry
    static DeleteCurrentEntry() {
        dateStr := this.GetSelectedDateStr()
        if (!this.data.Has(dateStr)) {
            this.edStart.Value := ""
            this.edEnd.Value := ""
            this.edLunch.Value := "20"
            this.chkHomeOffice.Value := 0
            this.edNote.Value := ""
            this.sb.SetText("No entry existed for " . dateStr)
            this.RefreshAll()
            return
        }

        ans := MsgBox("Are you sure you want to delete the entry for " . dateStr . "?", "Confirm Delete", "YesNo Icon?")
        if (ans != "Yes")
            return

        this.data.Delete(dateStr)
        this.SaveData()
        this.edStart.Value := ""
        this.edEnd.Value := ""
        this.edLunch.Value := "20"
        this.chkHomeOffice.Value := 0
        this.edNote.Value := ""
        this.RefreshAll()
        this.sb.SetText("Deleted entry for " . dateStr)
    }

    ; Open CSV file
    static OpenCsv() {
        if (!FileExist(this.csvPath))
            this.SaveData()
        Run(this.csvPath)
    }

    ; Minute timer tick
    static OnTimerTick() {
        todayStr := FormatTime(A_Now, "yyyy-MM-dd")
        if (this.gui != "" && this.GetSelectedDateStr() == todayStr) {
            this.UpdateLiveStatus()
        }
    }

    ; Refresh all UI elements
    static RefreshAll() {
        this.LoadData()
        this.UpdateLiveStatus()
        this.UpdateStatsTable()
        this.UpdateMissingUI()
    }

    ; Live day status calculation
    static UpdateLiveStatus() {
        dateStr := this.GetSelectedDateStr()
        target := this.GetDayTarget(dateStr)
        startStr := Trim(this.edStart.Value)
        endStr := Trim(this.edEnd.Value)
        lunchVal := Trim(this.edLunch.Value)
        lunchMins := (lunchVal != "" && IsInteger(lunchVal)) ? Integer(lunchVal) : 20

        todayStr := FormatTime(A_Now, "yyyy-MM-dd")
        isToday := (dateStr == todayStr)

        sMins := this.ParseTimeToMinutes(startStr)
        eMins := this.ParseTimeToMinutes(endStr)
        hoTag := (this.chkHomeOffice.Value) ? " [Home Office]" : ""

        statusText := ""

        if (sMins >= 0 && eMins >= 0) {
            gross := eMins - sMins
            net := (gross > lunchMins) ? gross - lunchMins : 0
            balance := net - target
            statusText := "Target: " . this.FormatMins(target) 
                        . "  |  Worked: " . this.FormatMins(net) 
                        . "  |  Balance: " . this.FormatMins(balance, true) . hoTag . "`n"
                        . "Status: Day Completed (" . this.FormatMins(net) . " net worked)" . hoTag
        } else if (sMins >= 0 && isToday) {
            nowMins := Integer(FormatTime(A_Now, "H")) * 60 + Integer(FormatTime(A_Now, "m"))
            gross := nowMins - sMins
            net := (gross > lunchMins) ? gross - lunchMins : Max(0, gross)
            balance := net - target

            expEndMins := sMins + target + lunchMins
            expEndStr := this.MinutesToTimeStr(expEndMins)
            remMins := Max(0, target - net)

            statusText := "Target: " . this.FormatMins(target) 
                        . "  |  Worked so far: " . this.FormatMins(net) 
                        . "  |  Balance: " . this.FormatMins(balance, true) . hoTag . "`n"
                        . "Status: Working since " . startStr 
                        . "  |  Expected End: " . expEndStr 
                        . "  (" . this.FormatMins(remMins) . " remaining)" . hoTag
        } else if (sMins >= 0) {
            statusText := "Target: " . this.FormatMins(target) 
                        . "  |  Start: " . startStr . "`n"
                        . "Status: ⚠️ INCOMPLETE ENTRY — Missing end time for this past workday!"
        } else if (StrCompare(dateStr, todayStr) < 0 && target > 0) {
            statusText := "Target: " . this.FormatMins(target) . "`n"
                        . "Status: ⚠️ UNRECORDED WORKDAY — No hours logged for this past workday!"
        } else if (isToday) {
            statusText := "Target: " . this.FormatMins(target) . "`n"
                        . "Status: Not started yet today"
        } else if (StrCompare(dateStr, todayStr) > 0 && target > 0) {
            statusText := "Target: " . this.FormatMins(target) . "`n"
                        . "Status: Future workday"
        } else {
            statusText := "Target: " . this.FormatMins(target) . "`n"
                        . "Status: Rest day / Weekend"
        }

        if (this.txtDayStatus != "")
            this.txtDayStatus.Text := statusText
    }

    ; Update Statistics ListView
    static UpdateStatsTable() {
        if (this.lvStats == "")
            return

        todayStr := FormatTime(A_Now, "yyyy-MM-dd")

        calcData := Map()
        for k, v in this.data
            calcData[k] := v

        ; Incorporate active inputs if currently viewing today
        dateStr := this.GetSelectedDateStr()
        if (dateStr == todayStr) {
            startVal := Trim(this.edStart.Value)
            endVal := Trim(this.edEnd.Value)
            lunchVal := Trim(this.edLunch.Value)
            lunchMins := (lunchVal != "" && IsInteger(lunchVal)) ? Integer(lunchVal) : 20
            noteVal := Trim(this.edNote.Value)
            if (startVal != "" || endVal != "") {
                calcData[todayStr] := {
                    date: todayStr,
                    start: startVal,
                    end: endVal,
                    lunch: lunchMins,
                    note: noteVal
                }
            }
        }

        ; --- 1. Today Stats ---
        todayTarget := this.GetDayTarget(todayStr)
        todayWorked := calcData.Has(todayStr) ? this.CalculateDayWorked(calcData[todayStr], true) : 0
        todayBalance := todayWorked - todayTarget
        todayRemaining := Max(0, todayTarget - todayWorked)

        ; --- 2. This Week Stats (Monday to Sunday) ---
        wday := Integer(FormatTime(A_Now, "WDay"))
        offset := (wday == 1) ? -6 : -(wday - 2)
        monDate := DateAdd(A_Now, offset, "days")

        weekWorked := 0
        weekTargetSoFar := 0
        weekTargetFull := 0

        loop 7 {
            dObj := DateAdd(monDate, A_Index - 1, "days")
            dStr := FormatTime(dObj, "yyyy-MM-dd")
            t := this.GetDayTarget(dStr)
            weekTargetFull += t
            if (StrCompare(dStr, todayStr) <= 0)
                weekTargetSoFar += t
            if (calcData.Has(dStr))
                weekWorked += this.CalculateDayWorked(calcData[dStr], dStr == todayStr)
        }
        weekBalance := weekWorked - weekTargetSoFar
        weekRemaining := Max(0, weekTargetFull - weekWorked)

        ; --- 3. This Month Stats ---
        ym := FormatTime(A_Now, "yyyyMM")
        firstOfNext := SubStr(DateAdd(ym . "01", 32, "days"), 1, 6) . "01"
        daysInMonth := Integer(FormatTime(DateAdd(firstOfNext, -1, "days"), "d"))

        monthWorked := 0
        monthTargetSoFar := 0
        monthTargetFull := 0

        loop daysInMonth {
            dStr := FormatTime(Format("{}{:02d}", ym, A_Index), "yyyy-MM-dd")
            t := this.GetDayTarget(dStr)
            monthTargetFull += t
            if (StrCompare(dStr, todayStr) <= 0)
                monthTargetSoFar += t
            if (calcData.Has(dStr))
                monthWorked += this.CalculateDayWorked(calcData[dStr], dStr == todayStr)
        }
        monthBalance := monthWorked - monthTargetSoFar
        monthRemaining := Max(0, monthTargetFull - monthWorked)

        ; --- 4. All Time Stats ---
        allWorked := 0
        allTarget := 0
        for d, entry in calcData {
            t := this.GetDayTarget(entry.date)
            allTarget += t
            allWorked += this.CalculateDayWorked(entry, entry.date == todayStr)
        }
        allBalance := allWorked - allTarget
        allRemaining := Max(0, allTarget - allWorked)

        this.lvStats.Delete()

        this.lvStats.Add(, "Today", 
            this.FormatMins(todayWorked), 
            this.FormatMins(todayTarget), 
            this.FormatMins(todayBalance, true),
            this.FormatMins(todayRemaining))

        this.lvStats.Add(, "This Week", 
            this.FormatMins(weekWorked), 
            this.FormatMins(weekTargetSoFar) . " (" . this.FormatMins(weekTargetFull) . ")", 
            this.FormatMins(weekBalance, true),
            this.FormatMins(weekRemaining))

        this.lvStats.Add(, "This Month", 
            this.FormatMins(monthWorked), 
            this.FormatMins(monthTargetSoFar) . " (" . this.FormatMins(monthTargetFull) . ")", 
            this.FormatMins(monthBalance, true),
            this.FormatMins(monthRemaining))

        this.lvStats.Add(, "All Time", 
            this.FormatMins(allWorked), 
            this.FormatMins(allTarget), 
            this.FormatMins(allBalance, true),
            this.FormatMins(allRemaining))
    }

    static CalculateDayWorked(entry, isToday := false) {
        if (!entry || entry.start == "")
            return 0

        sMins := this.ParseTimeToMinutes(entry.start)
        eMins := this.ParseTimeToMinutes(entry.end)
        lunchMins := entry.lunch

        if (sMins < 0)
            return 0

        if (eMins >= 0) {
            gross := eMins - sMins
            if (gross <= 0)
                return 0
            net := (gross > lunchMins) ? gross - lunchMins : 0
            return net
        }

        if (isToday) {
            nowMins := Integer(FormatTime(A_Now, "H")) * 60 + Integer(FormatTime(A_Now, "m"))
            gross := nowMins - sMins
            if (gross <= 0)
                return 0
            net := (gross > lunchMins) ? gross - lunchMins : gross
            return net
        }

        return 0
    }

    ; Daily target minutes (Mon-Thu: 500m = 8h 20m, Fri: 400m = 6h 40m)
    static GetDayTarget(dateStr) {
        clean := StrReplace(dateStr, "-")
        wday := Integer(FormatTime(clean, "WDay"))
        if (wday >= 2 && wday <= 5)
            return 500
        else if (wday == 6)
            return 400
        return 0
    }

    static ParseTimeToMinutes(timeStr) {
        timeStr := Trim(timeStr)
        if (!RegExMatch(timeStr, "^(\d{1,2}):(\d{2})$", &m))
            return -1
        h := Integer(m[1])
        mins := Integer(m[2])
        if (h < 0 || h > 23 || mins < 0 || mins > 59)
            return -1
        return h * 60 + mins
    }

    static MinutesToTimeStr(mins) {
        if (mins < 0)
            return ""
        h := Mod(mins // 60, 24)
        m := Mod(mins, 60)
        return Format("{:02d}:{:02d}", h, m)
    }

    static FormatMins(mins, showSign := false) {
        s := mins < 0 ? "-" : (showSign && mins > 0 ? "+" : "")
        a := Abs(mins)
        h := a // 60
        m := Mod(a, 60)
        return s . h . "h " . (m < 10 ? "0" : "") . m . "m"
    }

    static GetSelectedDateStr() {
        return FormatTime(this.dtControl.Value, "yyyy-MM-dd")
    }

    static LoadData() {
        this.data := Map()
        if (!FileExist(this.csvPath))
            return

        content := FileRead(this.csvPath, "UTF-8")
        hasHoCol := false
        for line in StrSplit(content, "`n", "`r") {
            line := Trim(line)
            if (line == "")
                continue
            if (SubStr(line, 1, 4) == "Date") {
                if (InStr(line, "HomeOffice") || InStr(line, "HO"))
                    hasHoCol := true
                continue
            }
            parts := StrSplit(line, ",")
            if (parts.Length >= 4) {
                d := Trim(parts[1])
                s := Trim(parts[2])
                e := Trim(parts[3])
                l := (parts[4] != "" && IsInteger(Trim(parts[4]))) ? Integer(Trim(parts[4])) : 20
                ho := 0
                n := ""
                if (hasHoCol) {
                    ho := (parts.Length >= 5 && parts[5] != "" && IsInteger(Trim(parts[5]))) ? Integer(Trim(parts[5])) : 0
                    n := parts.Length >= 6 ? Trim(parts[6]) : ""
                } else {
                    n := parts.Length >= 5 ? Trim(parts[5]) : ""
                }
                this.data[d] := { date: d, start: s, end: e, lunch: l, ho: ho, note: n }
            }
        }
    }

    static SaveData() {
        dates := []
        for d in this.data
            dates.Push(d)

        dates := this.SortDates(dates)

        out := "Date,Start,End,Lunch,HomeOffice,Note`n"
        for d in dates {
            entry := this.data[d]
            hoVal := (entry.HasProp("ho") && entry.ho) ? 1 : 0
            out .= entry.date . "," . entry.start . "," . entry.end . "," . entry.lunch . "," . hoVal . "," . entry.note . "`n"
        }

        f := FileOpen(this.csvPath, "w", "UTF-8")
        f.Write(out)
        f.Close()
    }

    static SortDates(arr) {
        n := arr.Length
        if (n <= 1)
            return arr
        loop n - 1 {
            i := A_Index
            loop n - i {
                j := A_Index + i
                if (StrCompare(arr[i], arr[j]) > 0) {
                    tmp := arr[i]
                    arr[i] := arr[j]
                    arr[j] := tmp
                }
            }
        }
        return arr
    }

    ; --- Missing & Incomplete Workdays Management ---

    ; Scan past workdays for missing entries or incomplete hours
    static GetMissingWorkdays(scope := "first_entry") {
        todayStr := FormatTime(A_Now, "yyyy-MM-dd")
        todayDate := SubStr(StrReplace(todayStr, "-"), 1, 8)

        if (scope == "first_entry") {
            startDateStr := ""
            for d in this.data {
                if (startDateStr == "" || StrCompare(d, startDateStr) < 0)
                    startDateStr := d
            }
            if (startDateStr == "")
                startDateStr := FormatTime(DateAdd(A_Now, -14, "days"), "yyyy-MM-dd")
        } else if (scope == "month") {
            startDateStr := SubStr(todayStr, 1, 8) . "01"
        } else if (scope == "past14") {
            startDateStr := FormatTime(DateAdd(A_Now, -14, "days"), "yyyy-MM-dd")
        } else { ; past30
            startDateStr := FormatTime(DateAdd(A_Now, -30, "days"), "yyyy-MM-dd")
        }

        startDate := SubStr(StrReplace(startDateStr, "-"), 1, 8)
        yesterdayDate := SubStr(DateAdd(todayDate, -1, "days"), 1, 8)

        missing := []
        currDate := startDate

        while (StrCompare(currDate, yesterdayDate) <= 0) {
            clean := currDate
            wday := Integer(FormatTime(clean, "WDay")) ; 1=Sun, 2=Mon... 6=Fri, 7=Sat
            dStr := FormatTime(clean, "yyyy-MM-dd")
            dayName := FormatTime(clean, "ddd")
            isWorkday := (wday >= 2 && wday <= 6)
            targetStr := (wday == 6) ? "6h 40m" : (isWorkday ? "8h 20m" : "0h 00m")

            if (!this.data.Has(dStr)) {
                if (isWorkday)
                    missing.Push({ date: dStr, day: dayName, issue: "Not recorded", type: "missing", target: targetStr })
            } else {
                entry := this.data[dStr]
                s := Trim(entry.start)
                e := Trim(entry.end)
                n := Trim(entry.note)

                if (s != "" && e == "") {
                    missing.Push({ date: dStr, day: dayName, issue: "Missing End time", type: "no_end", target: targetStr })
                } else if (s == "" && e != "") {
                    missing.Push({ date: dStr, day: dayName, issue: "Missing Start time", type: "no_start", target: targetStr })
                } else if (s == "" && e == "" && n == "" && isWorkday) {
                    missing.Push({ date: dStr, day: dayName, issue: "Empty record", type: "empty", target: targetStr })
                }
            }
            currDate := SubStr(DateAdd(currDate, 1, "days"), 1, 8)
        }

        return missing
    }

    ; Update dropdown in the top navigation bar and status bar alert
    static UpdateMissingUI() {
        if (this.ddlMissing == "")
            return

        missingList := this.GetMissingWorkdays("first_entry")
        this.ddlMissing.Delete()

        if (missingList.Length == 0) {
            this.ddlMissing.Add(["✔ All past days logged"])
            this.ddlMissing.Choose(1)
            this.sb.SetText("Ready. All past workdays recorded.")
        } else {
            items := []
            ; Show most recent first so yesterday is right at the top
            loop missingList.Length {
                idx := missingList.Length - A_Index + 1
                item := missingList[idx]
                tag := (item.type == "no_end") ? "(No End)" : (item.type == "no_start" ? "(No Start)" : "(Missing)")
                items.Push("⚠️ " . item.date . " " . tag)
            }
            this.ddlMissing.Add(items)
            this.ddlMissing.Choose(1)

            mostRecent := missingList[missingList.Length]
            this.sb.SetText("⚠️ " . missingList.Length . " missing/incomplete entry found (e.g. " . mostRecent.date . " - " . mostRecent.issue . ").")
        }
    }

    ; Jump to date when selected from the dropdown
    static OnMissingSelected() {
        val := this.ddlMissing.Text
        if (!RegExMatch(val, "(\d{4}-\d{2}-\d{2})", &m))
            return
        targetDate := m[1]
        this.JumpToDate(targetDate)
    }

    ; Navigate to a specific date in the main editor
    static JumpToDate(dateStr) {
        this.dtControl.Value := StrReplace(dateStr, "-")
        this.OnDateChanged()

        ; Focus End if Start is already present, else focus Start
        if (Trim(this.edStart.Value) != "" && Trim(this.edEnd.Value) == "")
            this.edEnd.Focus()
        else
            this.edStart.Focus()
    }

    static GetFirstLogDate() {
        startDateStr := ""
        for d in this.data {
            if (startDateStr == "" || StrCompare(d, startDateStr) < 0)
                startDateStr := d
        }
        return (startDateStr != "") ? startDateStr : FormatTime(A_Now, "yyyy-MM-dd")
    }

    ; Open dedicated modal dialog to inspect all missing days with scope filtering
    static ShowMissingDialog() {
        if (this.missingDlg != "") {
            try {
                this.missingDlg.Show()
                return
            } catch {
                this.missingDlg := ""
            }
        }

        dlg := Gui("+Owner" . this.gui.Hwnd . " +ToolWindow", "Missing & Incomplete Workdays")
        this.missingDlg := dlg
        dlg.SetFont("s10", "Segoe UI")

        dlg.Add("Text", "xm y15 w50", "Scope:")
        ddlScope := dlg.Add("DropDownList", "x+5 yp-3 w250 Choose1", [
            "Since First Log (" . this.GetFirstLogDate() . ")",
            "This Month (" . FormatTime(A_Now, "MMMM yyyy") . ")",
            "Past 14 Days",
            "Past 30 Days"
        ])

        lv := dlg.Add("ListView", "xm y+15 w465 h200 -Multi +Grid", ["Date", "Day", "Status / Issue", "Target"])
        lv.ModifyCol(1, 95)
        lv.ModifyCol(2, 55)
        lv.ModifyCol(3, 215)
        lv.ModifyCol(4, 80)

        PopulateList(*) {
            lv.Delete()
            scopeMap := ["first_entry", "month", "past14", "past30"]
            selScope := scopeMap[ddlScope.Value]
            list := WorktimeLogger.GetMissingWorkdays(selScope)

            if (list.Length == 0) {
                lv.Add(, "-", "-", "✔ No missing entries found for this scope!", "-")
                return
            }

            loop list.Length {
                idx := list.Length - A_Index + 1
                item := list[idx]
                issueIcon := (item.type == "no_end" || item.type == "no_start") ? "⚠️ " : "❌ "
                lv.Add(, item.date, item.day, issueIcon . item.issue, item.target)
            }
        }

        ddlScope.OnEvent("Change", PopulateList)

        btnJump := dlg.Add("Button", "xm y+15 w130 h30 Default", "👉 Jump to Date")
        btnJump.ToolTip := "Jump to selected date in main editor"
        btnJump.OnEvent("Click", (*) => JumpFromList())

        btnFillDefault := dlg.Add("Button", "x+10 yp w155 h30", "⚡ Fill with Default")
        btnFillDefault.ToolTip := "Fill standard hours for selected date and save directly"
        btnFillDefault.OnEvent("Click", (*) => FillDefaultFromList())

        btnClose := dlg.Add("Button", "x+10 yp w90 h30", "Close")
        btnClose.OnEvent("Click", (*) => dlg.Destroy())

        JumpFromList() {
            row := lv.GetNext()
            if (row == 0)
                return
            dStr := lv.GetText(row, 1)
            if (dStr == "-" || !RegExMatch(dStr, "^\d{4}-\d{2}-\d{2}$"))
                return
            dlg.Destroy()
            WorktimeLogger.JumpToDate(dStr)
        }

        FillDefaultFromList() {
            row := lv.GetNext()
            if (row == 0) {
                MsgBox("Please select a date from the list first.", "No Selection", "Icon!")
                return
            }
            dStr := lv.GetText(row, 1)
            if (dStr == "-" || !RegExMatch(dStr, "^\d{4}-\d{2}-\d{2}$"))
                return

            clean := StrReplace(dStr, "-")
            wday := Integer(FormatTime(clean, "WDay"))
            endTime := (wday == 6) ? "15:00" : "16:40"

            WorktimeLogger.data[dStr] := {
                date: dStr,
                start: "08:00",
                end: endTime,
                lunch: 20,
                ho: 0,
                note: ""
            }
            WorktimeLogger.SaveData()
            WorktimeLogger.RefreshAll()
            PopulateList()
        }

        lv.OnEvent("DoubleClick", (*) => JumpFromList())
        dlg.OnEvent("Escape", (*) => dlg.Destroy())

        PopulateList()
        dlg.Show("w490")
    }
}

; Ctrl+S hotkey to save when Worktime Logger window is active
#HotIf (WorktimeLogger.gui != "" && WinActive("ahk_id " . WorktimeLogger.gui.Hwnd))
^s::WorktimeLogger.SaveCurrentEntry()
#HotIf

; Standalone launch
if (A_LineFile == A_ScriptFullPath) {
    WorktimeLogger.Show()
}
