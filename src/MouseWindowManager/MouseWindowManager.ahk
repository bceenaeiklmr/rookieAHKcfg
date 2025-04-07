; Script     MouseWindowManager.ahk
; License:   MIT License
; Author:    Bence Markiel (bceenaeiklmr)
; Github:    https://github.com/bceenaeiklmr/MouseWindowManager
; Date       04.05.2025
; Version    0.2

#Requires AutoHotkey v2.0
#SingleInstance Force

; Hotkeys for cycling window size
;#WheelUp::CycleWindowSize(1)      ; Increase size on Win+WheelUp
;#WheelDown::CycleWindowSize(0)    ; Decrease size on Win+WheelDown

; Hotkeys for cycling window transparency
;#!WheelUp::CycleWindowTransparency(1)   ; increase Win + Alt + WheelUp
;#!WheelDown::CycleWindowTransparency(0) ; decrease Win + Alt + WheelDown

; Function to test the ASCII progress bar
AsciiProgressbarTest() {

    local g, gEdit, str

    ; Create a GUI with and Edit control.
    g := Gui()
    gEdit := g.Add("Edit", "R50")

    ; Create string with progress bar values.
    str := ""
    loop 255 {
        str .= AsciiProgressbarHorizontal(A_Index, 255) "`n"
    }

    ; Edit control, show GUI.
    gEdit.Value := SubStr(str, 1, -1)
    g.Show("NA")
}

; Generate a horizontal ASCII progress bar.
AsciiProgressbarHorizontal(current, goal := 100, char := ['◼', '◻'], scale := 1) {

    local progress, str

    progress := Round(current / goal * 10)
    loop progress * scale {
        str .= char[1]
    }
    loop (10 - progress) * scale {
        str .= char[2]
    }
    return str
}

; Cycle through window sizes.
; Increment: Direction of resize (1 for increase, 0 for decrease).
CycleWindowSize(increment := 1) {

    local x, y, w, h, hwnd, mon, left, top, right, bot
    local dontMove, winDelay, winState, percent, monitor
    
     ; Store the previous state to detect changes.
    static xywhPrevious := 0
    
    ; Get monitors.
    monitor := []
    loop MonitorGetCount() {
        try {
            MonitorGet(A_Index, &left, &top, &right, &bot)
            monitor.Push({x : left, y : top, w : right - left, h : bot - top})
        }
        catch {
            throw("Monitor " A_Index ", error occurred.")
        }
    }
    
    ; Find which monitor the window is on.
    MouseGetPos(,, &hwnd)
    WinGetPos(&x, &y, &w, &h, hwnd)
    
    ; Center.
    x := x + w / 2
    y := y + h / 2
    
    ; Find the monitor containing the center of the window.
    for m in monitor {
        if (x >= m.x && x < m.x + m.w 
         && y >= m.y && y < m.y + m.h) {
            mon := m
            break
        }
    }
    
    ; Calculate the new size.
    percent := w / mon.w * 100
    percent += (increment) ? 10 : -10 
    
    if (percent >= 100)
        percent := 100
    else if (percent < 10)
        percent := 10

    percent := (Integer(percent) // 10) * 10
    
    w := Floor(mon.w * percent / 100)
    h := Floor(w * mon.h / mon.w)
    x := mon.x + (mon.w - w) // 2
    y := mon.y + (mon.h - h) // 2

    ; Check previous window dimensions.
    if (xywhPrevious !== x y w h) {

        ; Set window delay to 0 to avoid flickering.
        winDelay := A_WinDelay
        winState := WinGetMinMax(hwnd)
        SetWinDelay(0)

        ; Window minimized, increment.
        if (percent = 100 && winState = 0 && increment = 1) {
            WinMaximize(hwnd)
            dontMove := true
        }
        ; Window maximized, decrement.
        else if (winState = 1 && increment = 0) {
            WinRestore(hwnd)
        }
        
        ; Move window to new position.
        if !IsSet(dontMove) {
            WinMove(x, y, w, h, hwnd)
        }

        ; Restore WinDelay, tooltip.
        SetWinDelay(winDelay)
        Tooltip(Format("{:3}", percent) "% " AsciiProgressbarHorizontal(percent))
        SetTimer(() => ToolTip(), -1000)
    }
    
    ; Update previous state.
    xywhPrevious := x y w h
    return
}

; Cycle through window transparency levels.
; Increment: Direction of transparency change (1 for increase, 0 for decrease).
; Step: Amount to change transparency by (default 17).
CycleWindowTransparency(increment := 1, step := 17) {

    local hwnd, transp
    
    ; Clamp step value between 1 and 255
    step := (step > 255) ? 255 : (step < 1) ? 1 : step
    
    ; Get the window handle under the mouse
    MouseGetPos(,, &hwnd)
    
    ; New transparency.
    transp := WinGetTransparent(hwnd)
    transp := (transp == "") ? 255 : transp
    transp += step * (increment ? 1 : -1)

    if (transp > 255)
        transp := 255
    else if (transp < step)
        transp := step
    
    WinSetTransparent(transp, hwnd)

    ; Tooltip.
    ToolTip(AsciiProgressbarHorizontal(transp, 255) ' ' Format("{:3}", transp) " / 255")
    SetTimer(() => ToolTip(), -1000)
    return
}
