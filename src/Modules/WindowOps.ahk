#Requires AutoHotkey v2.0

; Center a window within the work area of its current monitor
WinSetCenter(title := "A", activate := true) {
    if (!hwnd := WinExist(title))
        return false

    ; Restore window if minimized
    if (WinGetMinMax(hwnd) == -1)
        WinRestore(hwnd)

    WinGetPos(&wx, &wy, &ww, &wh, hwnd)

    cx := wx + ww // 2
    cy := wy + wh // 2

    monitorCount := MonitorGetCount()
    loop monitorCount {
        MonitorGetWorkArea(A_Index, &left, &top, &right, &bottom)

        if (cx >= left && cx < right && cy >= top && cy < bottom) {
            newX := left + ((right - left) - ww) // 2
            newY := top + ((bottom - top) - wh) // 2
            WinMove(newX, newY,,, hwnd)

            if (activate && !WinActive(hwnd))
                WinActivate(hwnd)
            return true
        }
    }

    ; Fallback to primary monitor work area
    MonitorGetWorkArea(1, &left, &top, &right, &bottom)
    newX := left + ((right - left) - ww) // 2
    newY := top + ((bottom - top) - wh) // 2
    WinMove(newX, newY,,, hwnd)

    if (activate && !WinActive(hwnd))
        WinActivate(hwnd)

    return true
}

; Move active window to next monitor, preserving maximized state and supporting vertical layouts
WindowNextMonitor() {
    monCount := MonitorGetCount()
    if (monCount <= 1)
        return

    mon := []
    loop monCount {
        try {
            MonitorGetWorkArea(A_Index, &left, &top, &right, &bot)
            mon.Push({x : left, y : top, w : right - left, h : bot - top})
        } catch {
            MonitorGet(A_Index, &left, &top, &right, &bot)
            mon.Push({x : left, y : top, w : right - left, h : bot - top})
        }
    }

    if (!hwnd := WinExist("A"))
        return

    wasMax := (WinGetMinMax(hwnd) == 1)
    if (wasMax)
        WinRestore(hwnd)

    WinGetPos(&x, &y, &w, &h, hwnd)
    cx := x + w // 2
    cy := y + h // 2

    currentMon := 1
    for idx, m in mon {
        if (cx >= m.x && cx < m.x + m.w && cy >= m.y && cy < m.y + m.h) {
            currentMon := idx
            break
        }
    }

    nextMon := (currentMon >= mon.Length) ? 1 : (currentMon + 1)
    target := mon[nextMon]

    targetW := Min(w, target.w)
    targetH := Min(h, target.h)
    newX := target.x + (target.w - targetW) // 2
    newY := target.y + (target.h - targetH) // 2

    WinMove(newX, newY, targetW, targetH, hwnd)

    if (wasMax)
        WinMaximize(hwnd)

    return
}

; Toggle Always-On-Top for active window with visual feedback
WinToggleAlwaysOnTop(title := "A") {
    if (!hwnd := WinExist(title))
        return

    WinSetAlwaysOnTop(-1, hwnd)
    isTop := (WinGetExStyle(hwnd) & 0x8) ; WS_EX_TOPMOST

    ToolTip(isTop ? "📌 Always-on-Top: ON" : "Always-on-Top: OFF")
    SetTimer(() => ToolTip(), -1000)
}

; Toggle desktop icons visibility (credit: SKAN)
DesktopIcons(Show := -1) {
    hProgman := WinExist("ahk_class WorkerW", "FolderView") ? WinExist()
             :  WinExist("ahk_class Progman", "FolderView")

    if (!hProgman)
        return

    hShellDefView := DllCall("user32.dll\GetWindow", "ptr", hProgman, "int", 5, "ptr")
    hSysListView  := DllCall("user32.dll\GetWindow", "ptr", hShellDefView, "int", 5, "ptr")

    if (DllCall("user32.dll\IsWindowVisible", "ptr", hSysListView) !== Show)
        DllCall("user32.dll\SendMessage", "ptr", hShellDefView, "ptr", 0x111, "ptr", 0x7402, "ptr", 0)
}
