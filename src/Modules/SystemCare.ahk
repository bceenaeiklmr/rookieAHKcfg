#Requires AutoHotkey v2.0

; System Care, Drive Monitoring & Maintenance Utilities
; Provides safe OS maintenance, disk telemetry, and system actions.

/**
 * Format bytes into human-readable string (B, KB, MB, GB, TB).
 * @param {Integer} bytes
 * @returns {String}
 */
FormatBytes(bytes) {
    static units := ["B", "KB", "MB", "GB", "TB"]
    local size := Float(bytes), unitIdx := 1
    while (size >= 1024 && unitIdx < units.Length) {
        size /= 1024
        unitIdx++
    }
    return (unitIdx == 1) ? Format("{:d} B", size) : Format("{:.1f} {:s}", size, units[unitIdx])
}

/**
 * Retrieves storage details for all mounted fixed/removable drives.
 * @returns {Array<Object>} List of drive info objects.
 */
GetDrivesInfo() {
    local drives := DriveGetList("FIXED")
    local infoList := []

    loop parse, drives {
        local d := A_LoopField
        local path := d ":\"
        try {
            local freeMB := DriveGetSpaceFree(path)
            local capMB := DriveGetCapacity(path)
            local usedMB := capMB - freeMB
            local usedPct := capMB > 0 ? Round((usedMB / capMB) * 100) : 0
            local freePct := 100 - usedPct

            local label := Format("{:s}:  {:s} free of {:s} ({:d}%)", d, FormatBytes(freeMB * 1048576), FormatBytes(capMB * 1048576), freePct)
            infoList.Push({
                letter: d,
                freeBytes: freeMB * 1048576,
                capBytes: capMB * 1048576,
                usedPct: usedPct,
                freePct: freePct,
                label: label
            })
        }
    }
    return infoList
}

/**
 * Empty the Recycle Bin silently and report reclaimed space.
 * Uses Win32 SHQueryRecycleBinW and SHEmptyRecycleBinW.
 */
EmptyRecycleBinWithStats() {
    local SHQ := Buffer(24, 0)
    NumPut("UInt", 24, SHQ, 0)

    local hr := DllCall("shell32\SHQueryRecycleBinW", "Ptr", 0, "Ptr", SHQ, "UInt")
    if (hr != 0) {
        ToolTip("Could not query Recycle Bin")
        SetTimer(() => ToolTip(), -2500)
        return
    }

    local bytes := NumGet(SHQ, 8, "Int64")
    local items := NumGet(SHQ, 16, "Int64")

    if (items == 0) {
        ToolTip("Recycle Bin is already empty")
        SetTimer(() => ToolTip(), -2500)
        return
    }

    ; SHERB_NOCONFIRMATION (0x1) | SHERB_NOPROGRESSUI (0x2) | SHERB_NOSOUND (0x4) = 7
    local res := DllCall("shell32\SHEmptyRecycleBinW", "Ptr", 0, "Ptr", 0, "UInt", 7, "UInt")
    if (res == 0) {
        ToolTip(Format("Recycle Bin cleared: {:s} freed ({:d} items)", FormatBytes(bytes), items))
    } else {
        ToolTip("Recycle Bin cleanup cancelled or encountered an error")
    }
    SetTimer(() => ToolTip(), -3000)
}

/**
 * Safely purge stale files in %TEMP% older than the specified days.
 * Gracefully ignores locked or in-use files.
 * @param {Integer} [maxDays=2] Files older than this threshold are deleted.
 */
PurgeStaleTemp(maxDays := 2) {
    local freedBytes := 0
    local deletedCount := 0
    local cutoff := DateAdd(A_Now, -maxDays, "Days")
    local tempPattern := A_Temp "\*.*"

    loop files, tempPattern, "FR" {
        try {
            if (DateDiff(cutoff, A_LoopFileTimeModified, "Days") >= 0) {
                local fSize := A_LoopFileSize
                FileDelete(A_LoopFileFullPath)
                freedBytes += fSize
                deletedCount++
            }
        }
    }

    ; Prune empty directories left behind
    loop files, tempPattern, "DR" {
        try DirDelete(A_LoopFileFullPath)
    }

    if (deletedCount > 0) {
        ToolTip(Format("Temp purge: {:s} freed ({:d} files cleaned)", FormatBytes(freedBytes), deletedCount))
    } else {
        ToolTip("Temp folder is clean (no files older than " maxDays " days)")
    }
    SetTimer(() => ToolTip(), -3000)
}

/**
 * Restarts Windows Explorer cleanly to resolve taskbar or shell glitching.
 */
RestartExplorer() {
    ToolTip("Restarting Windows Explorer...")
    try RunWait("taskkill.exe /F /IM explorer.exe", , "Hide")
    try Run("explorer.exe")
    SetTimer(() => ToolTip(), -2000)
}

/**
 * Flushes Windows DNS Resolver Cache.
 */
FlushDNS() {
    try {
        RunWait("ipconfig.exe /flushdns", , "Hide")
        ToolTip("DNS Resolver Cache Flushed")
    } catch {
        ToolTip("Failed to flush DNS cache")
    }
    SetTimer(() => ToolTip(), -2500)
}

/**
 * Reboots the system directly into UEFI / BIOS firmware settings.
 */
RebootToUEFI() {
    if (MsgBox("Reboot computer directly into UEFI / BIOS firmware setup?", "Reboot to UEFI", "YesNo Icon? 256") == "Yes") {
        try Run("*RunAs shutdown.exe /r /fw /t 0")
        catch as err {
            MsgBox("Failed to initiate UEFI reboot: " err.Message, "Error", "Icon!")
        }
    }
}

/**
 * Toggle default microphone mute status and display visual OSD.
 */
ToggleMicMute() {
    local isMuted := false
    try {
        SoundSetMute("+1", , "Microphone")
        isMuted := SoundGetMute(, "Microphone")
    } catch {
        ; Search for available input capture devices
        loop {
            try {
                local dev := SoundGetName(, A_Index)
                if (InStr(dev, "Microphone") || InStr(dev, "Headset")) {
                    SoundSetMute("+1", , A_Index)
                    isMuted := SoundGetMute(, A_Index)
                    break
                }
            } catch {
                break
            }
        }
    }
    ToolTip(isMuted ? "[ Microphone: MUTED ]" : "[ Microphone: LIVE ]")
    SetTimer(() => ToolTip(), -2000)
}

/**
 * Retrieves the active local LAN IPv4 address.
 * @returns {String} IPv4 address or empty string.
 */
GetLocalIP() {
    local tmp := A_Temp "\local_ip.tmp"
    local ip := ""
    try {
        RunWait(A_ComSpec ' /c ipconfig > "' tmp '"', , "Hide")
        if FileExist(tmp) {
            local text := FileRead(tmp)
            try FileDelete(tmp)
            if RegExMatch(text, "IPv4[^\r\n:]*:\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)", &m)
                ip := m[1]
        }
    }
    return ip
}

/**
 * Copies the primary local LAN IP address to the clipboard.
 */
CopyLocalIP() {
    local ip := GetLocalIP()
    if (ip != "" && ip != "127.0.0.1") {
        A_Clipboard := ip
        ToolTip(Format("Copied LAN IP to clipboard: {:s}", ip))
    } else {
        ToolTip("No active LAN IP found")
    }
    SetTimer(() => ToolTip(), -2500)
}

/**
 * Rapid 1-packet ping test to verify internet connectivity and latency.
 * @param {String} [host="1.1.1.1"] Target IP or hostname.
 */
PingTest(host := "1.1.1.1") {
    local tmp := A_Temp "\ping_test.tmp"
    ToolTip("Pinging " host "...")
    try {
        RunWait(A_ComSpec ' /c ping -n 1 -w 1000 ' host ' > "' tmp '"', , "Hide")
        local res := FileRead(tmp)
        try FileDelete(tmp)
        if RegExMatch(res, "time[=<](\d+ms)", &m) {
            ToolTip(Format("Ping {:s}: Online ({:s})", host, m[1]))
        } else {
            ToolTip(Format("Ping {:s}: Offline / Request timed out", host))
        }
    } catch {
        ToolTip("Ping test failed to execute")
    }
    SetTimer(() => ToolTip(), -3000)
}

/**
 * Terminate all other AutoHotkey background processes except rookieAHKcfg.
 * @param {Boolean} [showTip=true] Whether to display a status ToolTip.
 * @returns {Integer} Count of terminated processes.
 */
KillOtherAHK(showTip := true) {
    local myPid, count, proc, cmdLine
    count := 0
    myPid := DllCall("GetCurrentProcessId", "uint")

    try {
        for proc in ComObjGet("winmgmts:").ExecQuery("Select ProcessId, Name, CommandLine from Win32_Process where Name like 'AutoHotkey%'") {
            if (proc.ProcessId != myPid) {
                cmdLine := ""
                try cmdLine := proc.CommandLine
                if (!InStr(cmdLine, "rookieAHKcfg.ahk")) {
                    try {
                        ProcessClose(proc.ProcessId)
                        count++
                    }
                }
            }
        }
    }

    if (showTip) {
        ToolTip(count > 0 ? Format("✓ Terminated {:d} AutoHotkey background process(es).", count) : "No other AutoHotkey processes found.")
        SetTimer(() => ToolTip(), -2500)
    }
    return count
}

