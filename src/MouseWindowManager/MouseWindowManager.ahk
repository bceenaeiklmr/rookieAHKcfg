; Script     MouseWindowManager.ahk
; License:   MIT License
; Author:    Bence Markiel (bceenaeiklmr)
; Github:    https://github.com/bceenaeiklmr/MouseWindowManager
; Date       18.05.2024
; Version    0.1

#Requires AutoHotkey >= v2.0.11
#SingleInstance Force

; Hotkeys for cycling window size
;#WheelUp::CycleWindowSize(1)      ; Increase size on Win+WheelUp
;#WheelDown::CycleWindowSize(0)    ; Decrease size on Win+WheelDown

; Hotkeys for cycling window transparency
;#!WheelUp::CycleWindowTransparency(1)   ; increase Win + Alt + WheelUp
;#!WheelDown::CycleWindowTransparency(0) ; decrease Win + Alt + WheelDown

; Function to test the ASCII progress bar
AsciiProgressbarTest() {
    local g := Gui() ; Create a new GUI
    gEdit := g.Add('Edit', 'R50') ; Add an Edit control to the GUI
    output := '' ; Initialize the output string
    loop 255
        output .= AsciiProgressbarHorizontal(A_Index, 255) '`n'
    gEdit.Value := SubStr(output, 1, -1) ; Set the value of the Edit control to the output string
    g.Show('NA') ; Show the GUI without activating it
}

; Generate a horizontal ASCII progress bar
; Current: Current value
; Goal: Goal value (default 100)
; Char: Character for filled portion (default '◼')
; Char2: Character for empty portion (default '◻')
AsciiProgressbarHorizontal(Current, Goal := 100, Char := '◼', Char2 := '◻') {
    str := '' ; Initialize the progress bar string
    progress := Round(Current / Goal * 10) ; Calculate progress in 10 steps
    loop progress ; Loop for the filled portion of the progress bar
        str .= Char
    loop 10 - progress ; Loop for the empty portion of the progress bar
        str .= Char2
    return str ; Return the progress bar string
}

; Cycle through window sizes
; Increment: Direction of resize (1 for increase, 0 for decrease)
CycleWindowSize(Increment := 1) {
    static PrevState := 0 ; Store the previous state to detect changes
    MouseGetPos(,, &hWnd) ; Get the window handle under the mouse
    WinGetPos(&x, &y, &Width, &Height, hWnd) ; Get the position and size of the window
    
    Percent := Width / A_ScreenWidth * 100 ; Calculate the width as a percentage of the screen width
    Percent += Increment ? 10 : -10 ; Increase or decrease the percentage by 10%
    
    ; Clamp the percentage between 10% and 100%
    if Percent >= 100
        Percent := 100
    else if Percent < 10
        Percent := 10
    
    ; Round to the nearest 10%
    Percent := (Integer(Percent) // 10) * 10
    
    ; Calculate the new width and maintain the aspect ratio
    Width := Floor(A_ScreenWidth * Percent / 100)
    Height := Floor(Width * A_ScreenHeight / A_ScreenWidth)
    
    ; Center the window
    x := (A_ScreenWidth - Width) // 2
    y := (A_ScreenHeight - Height) // 2

    ; If the state has changed, update the window size and position
    if PrevState != x y Width Height {
        WinDelay := A_WinDelay
        winState := WinGetMinMax(hWnd)
        SetWinDelay(0)
        if Percent = 100 && winState = 0 && Increment = 1 {
            WinMaximize(hWnd)
            DontMove := 1
        } else if winState = 1 && Increment = 0
            WinRestore(hWnd)
        if !IsSet(DontMove)
            WinMove(x, y, Width, Height, hWnd)
        SetWinDelay(WinDelay)
        Tooltip(Format("{:3}", Percent) "% " AsciiProgressbarHorizontal(Percent, 100, "◼", "◻"))
        SetTimer(() => ToolTip(), -1000)
    }
    
    PrevState := x y Width Height ; Update the previous state
}

; Cycle through window transparency levels
; Increment: Direction of transparency change (1 for increase, 0 for decrease)
; Step: Amount to change transparency by (default 17)
CycleWindowTransparency(Increment := 1, Step := 17) {
    ; Clamp step value between 1 and 255
    Step := (Step > 255) ? 255 : (Step < 1) ? 1 : Step
    
    ; Get the window handle under the mouse
    MouseGetPos(,, &hWnd)
    
    ; Get the current transparency level
    Transp := WinGetTransparent(hWnd)
    ; Default to fully opaque if not set
    Transp := Transp == '' ? 255 : Transp
    ; Adjust transparency
    Transp += Step * (Increment ? 1 : -1)

    ; Clamp transparency between minimum and maximum values
    if Transp > 255
        Transp := 255
    else if Transp < Step
        Transp := Step
    
    ; Set the new transparency level
    WinSetTransparent(Transp, hWnd)
    ToolTip(AsciiProgressbarHorizontal(Transp, 255, "◼", "◻") ' ' Format("{:3}", Transp) " / 255")
    ; Hide tooltip after 1 second
    SetTimer(() => ToolTip(), -1000)
}
