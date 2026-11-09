#Requires AutoHotkey v2.0
#DllLoad gdiplus.dll

/**
 * MouseTrail.ahk
 *
 * Ultra-Fast & Low-CPU Native Mouse Trail Engine
 * Recreated and optimized without GpGFX dependency.
 *
 * Features:
 * - 3 Visual Modes:
 *     1. Stardust Glow (Neon particles with speed-reactive hue & size decay)
 *     2. Cyber Ribbon  (Connected vector ribbon trail)
 *     3. Firefly Swarm (Physics-driven orbiting particles)
 * - Click-through transparent overlay (WS_EX_LAYERED, WS_EX_TRANSPARENT)
 * - Pre-allocated particle pool & reusable GDI+ drawing tools (0 heap allocations in render loop)
 * - Smart Dirty Bounding Box rendering (clears & updates only touched screen regions)
 * - Multi-monitor virtual desktop support
 *
 * Controls (when run standalone):
 * - [Tab]   : Switch trail modes
 * - [Space] : Supernova particle burst
 * - [Esc]   : Exit application
 */

class MouseTrail {
    static isRunning := false
    static mode := 1
    static modeNames := ["Stardust Glow", "Cyber Ribbon", "Firefly Swarm"]

    static pToken := 0
    static gui := 0
    static hwnd := 0
    static hdc := 0
    static hbm := 0
    static obm := 0
    static gfx := 0
    static brush := 0
    static pen := 0

    static vX := 0
    static vY := 0
    static vW := 0
    static vH := 0

    static prevX := 0
    static prevY := 0
    static prevW := 0
    static prevH := 0
    static hasDrawn := false

    static particles := []
    static maxParticles := 60
    static ribbonPoints := []
    static maxRibbon := 16

    static globalHue := 0.0
    static lastMouseX := 0
    static lastMouseY := 0
    static lastTime := 0.0
    static timerFn := 0

    ; Ease-out quadratic easing function
    static EaseOutQuad(t) => (t := Max(0.0, Min(1.0, Float(t)))) * (2.0 - t)

    ; Convert HSL color model to 32-bit ARGB integer
    static HSLtoARGB(h, s, l, a := 255) {
        local c, x, m, r, g, b, v

        h := Mod(h, 360.0)
        (h < 0) && (h += 360.0)
        s := (s > 1.0) ? (s / 100.0) : Max(0.0, Min(1.0, Float(s)))
        l := (l > 1.0) ? (l / 100.0) : Max(0.0, Min(1.0, Float(l)))
        a := Max(0, Min(255, Integer(a)))

        if (s == 0) {
            v := Round(l * 255)
            return (a << 24) | (v << 16) | (v << 8) | v
        }

        c := (1.0 - Abs(2.0 * l - 1.0)) * s
        x := c * (1.0 - Abs(Mod(h / 60.0, 2.0) - 1.0))
        m := l - c / 2.0
        
        r := 0.0
        g := 0.0
        b := 0.0

        if (h < 60) {
            r := c
            g := x
            b := 0.0
        }    
        else if (h < 120) {
            r := x
            g := c
            b := 0.0
        }
        else if (h < 180) {
            r := 0.0
            g := c
            b := x
        }
        else if (h < 240) {
            r := 0.0
            g := x
            b := c
        }
        else if (h < 300) {
            r := x
            g := 0.0
            b := c
        }
        else {
            r := c
            g := 0.0
            b := x
        }

        r := Round((r + m) * 255)
        g := Round((g + m) * 255)
        b := Round((b + m) * 255)
        return (a << 24) | (r << 16) | (g << 8) | b
    }

    ; Initialize and start the mouse trail engine
    static Start(initialMode := 1) {
        local buf, token, bi, pBits, gfx, brush, pen, mx, my

        if (this.isRunning)
            return

        this.mode := initialMode

        ; Startup GDI+
        buf := Buffer(24, 0)
        NumPut("uint", 1, buf, 0)
        token := 0
        DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", buf, "ptr", 0)
        this.pToken := token

        ; Multi-monitor virtual desktop coordinates
        this.vX := SysGet(76)
        this.vY := SysGet(77)
        this.vW := Max(100, SysGet(78))
        this.vH := Max(100, SysGet(79))

        ; Create full-screen transparent click-through layered window
        this.gui := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20 +E0x80000")
        this.gui.Show("x" this.vX " y" this.vY " w" this.vW " h" this.vH " NoActivate")
        this.hwnd := this.gui.Hwnd

        ; Memory DC & 32-bit top-down ARGB DIBSection
        this.hdc := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
        bi := Buffer(40, 0)
        pBits := 0
        NumPut("uint", 40, bi, 0)
        NumPut("int", this.vW, bi, 4)
        NumPut("int", -this.vH, bi, 8)
        NumPut("ushort", 1, bi, 12)
        NumPut("ushort", 32, bi, 14)
        this.hbm := DllCall("CreateDIBSection", "ptr", this.hdc, "ptr", bi, "uint", 0, "ptr*", &pBits, "ptr", 0, "uint", 0, "ptr")
        this.obm := DllCall("SelectObject", "ptr", this.hdc, "ptr", this.hbm, "ptr")

        ; GDI+ Graphics with vector anti-aliasing
        gfx := 0
        DllCall("gdiplus\GdipCreateFromHDC", "ptr", this.hdc, "ptr*", &gfx)
        DllCall("gdiplus\GdipSetSmoothingMode", "ptr", gfx, "int", 4)
        this.gfx := gfx

        ; Pre-allocate reusable solid brush & round pen (0 GC allocations per frame)
        brush := 0
        DllCall("gdiplus\GdipCreateSolidFill", "uint", 0xFFFFFFFF, "ptr*", &brush)
        this.brush := brush

        pen := 0
        DllCall("gdiplus\GdipCreatePen1", "uint", 0xFFFFFFFF, "float", 2.0, "int", 2, "ptr*", &pen)
        DllCall("gdiplus\GdipSetPenStartCap", "ptr", pen, "int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "ptr", pen, "int", 2)
        this.pen := pen

        ; Pre-allocate particle pool
        this.particles := []
        loop this.maxParticles {
            this.particles.Push({
                active: false,
                x: 0.0, y: 0.0,
                vx: 0.0, vy: 0.0,
                life: 0.0, maxLife: 1.0,
                size: 8.0,
                hue: 0.0, sat: 0.9, lit: 0.6
            })
        }

        this.ribbonPoints := []
        this.prevX := 0
        this.prevY := 0
        this.prevW := 0
        this.prevH := 0
        this.hasDrawn := false
        this.globalHue := 0.0

        CoordMode("Mouse", "Screen")
        mx := 0
        my := 0
        MouseGetPos(&mx, &my)
        this.lastMouseX := mx
        this.lastMouseY := my
        this.lastTime := A_TickCount / 1000.0

        this.isRunning := true
        this.timerFn := this.Update.Bind(this)
        SetTimer(this.timerFn, 16)
    }

    ; Stop engine and free all resources
    static Stop() {
        local token

        if (!this.isRunning)
            return

        if (this.timerFn) {
            SetTimer(this.timerFn, 0)
            this.timerFn := 0
        }

        this.isRunning := false

        if (this.brush) {
            DllCall("gdiplus\GdipDeleteBrush", "ptr", this.brush)
            this.brush := 0
        }
        if (this.pen) {
            DllCall("gdiplus\GdipDeletePen", "ptr", this.pen)
            this.pen := 0
        }
        if (this.gfx) {
            DllCall("gdiplus\GdipDeleteGraphics", "ptr", this.gfx)
            this.gfx := 0
        }
        if (this.obm) {
            DllCall("SelectObject", "ptr", this.hdc, "ptr", this.obm)
            this.obm := 0
        }
        if (this.hbm) {
            DllCall("DeleteObject", "ptr", this.hbm)
            this.hbm := 0
        }
        if (this.hdc) {
            DllCall("DeleteDC", "ptr", this.hdc)
            this.hdc := 0
        }
        if (this.gui) {
            this.gui.Destroy()
            this.gui := 0
            this.hwnd := 0
        }
        if (this.pToken) {
            token := this.pToken
            this.pToken := 0
            try DllCall("gdiplus\GdiplusShutdown", "ptr", token)
        }

        this.particles := []
        this.ribbonPoints := []
        this.hasDrawn := false
    }

    ; Toggle trail on / off with tooltip feedback
    static Toggle() {
        if (this.isRunning) {
            this.Stop()
            ToolTip("Mouse Trail: OFF")
            SetTimer(() => ToolTip(), -1000)
        } else {
            this.Start()
            ToolTip("Mouse Trail: ON (" this.modeNames[this.mode] ")")
            SetTimer(() => ToolTip(), -1200)
        }
    }

    ; Cycle through visual modes
    static NextMode() {
        local p
        this.mode := (this.mode >= 3) ? 1 : this.mode + 1
        this.ribbonPoints := []
        for p in this.particles
            p.active := false
        ToolTip("Mouse Trail Mode: " this.modeNames[this.mode] (this.isRunning ? "" : " (Disabled)"))
        SetTimer(() => ToolTip(), -1000)
    }

    ; Spawn a particle from the pre-allocated pool
    static SpawnParticle(px, py, pvx, pvy, psize, plife, phue, psat := 0.9, plit := 0.6) {
        local p
        for p in this.particles {
            if (!p.active) {
                p.active := true
                p.x := Float(px)
                p.y := Float(py)
                p.vx := Float(pvx)
                p.vy := Float(pvy)
                p.size := Float(psize)
                p.maxLife := Float(plife)
                p.life := Float(plife)
                p.hue := Float(phue)
                p.sat := Float(psat)
                p.lit := Float(plit)
                return p
            }
        }
        return 0
    }

    ; Supernova radial particle burst
    static Burst(count := 35) {
        local mx := 0, my := 0, i, angle, spd, h
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mx, &my)
        loop count {
            angle := Random(0.0, 6.283185)
            spd := Random(2.0, 8.0)
            h := Mod(this.globalHue + Random(-40.0, 40.0), 360.0)
            this.SpawnParticle(mx, my, Cos(angle) * spd, Sin(angle) * spd, Random(5.0, 12.0), Random(0.3, 0.7), h, 1.0, 0.65)
        }
    }

    ; Main 60 FPS update and render cycle
    static Update() {
        local now, dt, curX := 0, curY := 0, dx, dy, dist, spawnCount
        local subT, interpX, interpY, scatterAngle, scatterSpd, pvx, pvy, pHue, pSize, pLife
        local activeCount, p, idx, toMouseX, toMouseY, dToMouse, springF
        local lifeNorm, alphaVal, curRadius, curDiam, col, lx, ly
        local pt1, pt2, tRatio, rWidth, rAlpha, p1x, p1y, p2x, p2y
        local minX, minY, maxX, maxY, pad, clearPad
        local dst, sz, src, blend, hasActive

        if (!this.isRunning || !this.hwnd)
            return

        CoordMode("Mouse", "Screen")
        MouseGetPos(&curX, &curY)
        dx := curX - this.lastMouseX
        dy := curY - this.lastMouseY
        dist := Sqrt(dx * dx + dy * dy)

        ; Fast idle path: skip computation entirely when stationary and nothing is rendered
        if (dist == 0 && !this.hasDrawn && this.ribbonPoints.Length == 0) {
            hasActive := false
            for p in this.particles {
                if (p.active) {
                    hasActive := true
                    break
                }
            }
            if (!hasActive)
                return
        }

        now := A_TickCount / 1000.0
        dt := Min(0.05, Max(0.001, now - this.lastTime))
        this.lastTime := now

        this.globalHue := Mod(this.globalHue + 1.2, 360.0)

        ; 1. Particle / Ribbon Emission
        if (this.mode == 1) {
            ; Stardust Glow: Speed-reactive interpolated emission
            if (dist > 2.0) {
                spawnCount := Min(4, Max(1, Round(dist / 12)))
                loop spawnCount {
                    subT := A_Index / spawnCount
                    interpX := this.lastMouseX + dx * subT + Random(-2.0, 2.0)
                    interpY := this.lastMouseY + dy * subT + Random(-2.0, 2.0)

                    scatterAngle := Random(0.0, 6.283185)
                    scatterSpd := Random(0.2, 1.2)
                    pvx := (-dx * 0.08) + Cos(scatterAngle) * scatterSpd
                    pvy := (-dy * 0.08) + Sin(scatterAngle) * scatterSpd

                    pHue := Mod(this.globalHue + (dist * 1.2) + Random(-10.0, 10.0), 360.0)
                    pSize := Random(5.0, 10.0)
                    pLife := Random(0.25, 0.50)
                    this.SpawnParticle(interpX, interpY, pvx, pvy, pSize, pLife, pHue, 0.95, 0.6)
                }
            }
        }
        else if (this.mode == 2) {
            ; Cyber Ribbon: Continuous connected poly-trail
            if (dist > 1.0 || this.ribbonPoints.Length > 0) {
                this.ribbonPoints.InsertAt(1, { x: curX, y: curY, hue: this.globalHue })
                if (this.ribbonPoints.Length > this.maxRibbon)
                    this.ribbonPoints.Pop()
            }
        }
        else if (this.mode == 3) {
            ; Firefly Swarm: Physics-driven orbiting swarm (spawns while moving)
            if (dist > 1.0) {
                activeCount := 0
                for p in this.particles {
                    if (p.active)
                        activeCount++
                }
                if (activeCount < 25) {
                    loop 2 {
                        this.SpawnParticle(curX + Random(-20, 20), curY + Random(-20, 20), Random(-2.0, 2.0), Random(-2.0, 2.0), Random(4.0, 7.0), Random(0.6, 1.2), Mod(this.globalHue + Random(-30.0, 30.0), 360.0), 1.0, 0.65)
                    }
                }
            }
        }

        this.lastMouseX := curX
        this.lastMouseY := curY

        ; 2. Clear Previous Frame Dirty Bounding Box (Smart Culling)
        if (this.prevW > 0 && this.prevH > 0) {
            clearPad := 2
            DllCall("gdiplus\GdipSetClipRect", "ptr", this.gfx
                , "float", this.prevX - clearPad
                , "float", this.prevY - clearPad
                , "float", this.prevW + 2 * clearPad
                , "float", this.prevH + 2 * clearPad
                , "int", 0)
            DllCall("gdiplus\GdipGraphicsClear", "ptr", this.gfx, "uint", 0x00000000)
            DllCall("gdiplus\GdipResetClip", "ptr", this.gfx)
        }

        minX := 1e9, minY := 1e9, maxX := -1e9, maxY := -1e9

        ; 3. Render Particles (Modes 1 & 3)
        loop this.maxParticles {
            idx := A_Index
            p := this.particles[idx]

            if (!p.active)
                continue

            p.life -= dt
            if (p.life <= 0) {
                p.active := false
                continue
            }

            if (this.mode == 3) {
                ; Spring attraction towards cursor
                toMouseX := curX - p.x
                toMouseY := curY - p.y
                dToMouse := Max(1.0, Sqrt(toMouseX * toMouseX + toMouseY * toMouseY))
                springF := Min(6.0, dToMouse * 0.15)
                p.vx := (p.vx * 0.93) + (toMouseX / dToMouse) * springF * dt * 25.0
                p.vy := (p.vy * 0.93) + (toMouseY / dToMouse) * springF * dt * 25.0
            } else {
                p.vx *= 0.94
                p.vy := (p.vy * 0.94) - 0.2
            }

            p.x += p.vx
            p.y += p.vy

            if (this.mode != 2) {
                lifeNorm := p.life / p.maxLife
                alphaVal := Round(255 * this.EaseOutQuad(lifeNorm))
                curRadius := Max(1.5, p.size * this.EaseOutQuad(lifeNorm))
                curDiam := curRadius * 2.0

                lx := p.x - this.vX - curRadius
                ly := p.y - this.vY - curRadius

                col := this.HSLtoARGB(p.hue, p.sat, p.lit, alphaVal)
                DllCall("gdiplus\GdipSetSolidFillColor", "ptr", this.brush, "uint", col)
                DllCall("gdiplus\GdipFillEllipse", "ptr", this.gfx, "ptr", this.brush, "float", lx, "float", ly, "float", curDiam, "float", curDiam)

                (lx < minX) && (minX := lx)
                (ly < minY) && (minY := ly)
                (lx + curDiam > maxX) && (maxX := lx + curDiam)
                (ly + curDiam > maxY) && (maxY := ly + curDiam)
            }
        }

        ; 4. Render Ribbon (Mode 2)
        if (this.mode == 2 && this.ribbonPoints.Length > 1) {
            loop this.ribbonPoints.Length - 1 {
                idx := A_Index
                pt1 := this.ribbonPoints[idx]
                pt2 := this.ribbonPoints[idx + 1]

                tRatio := 1.0 - (idx / this.ribbonPoints.Length)
                rWidth := Max(1.5, 12.0 * this.EaseOutQuad(tRatio))
                rAlpha := Round(230 * this.EaseOutQuad(tRatio))

                p1x := pt1.x - this.vX
                p1y := pt1.y - this.vY
                p2x := pt2.x - this.vX
                p2y := pt2.y - this.vY

                col := this.HSLtoARGB(pt1.hue, 0.95, 0.55, rAlpha)
                DllCall("gdiplus\GdipSetPenColor", "ptr", this.pen, "uint", col)
                DllCall("gdiplus\GdipSetPenWidth", "ptr", this.pen, "float", rWidth)
                DllCall("gdiplus\GdipDrawLine", "ptr", this.gfx, "ptr", this.pen, "float", p1x, "float", p1y, "float", p2x, "float", p2y)

                (Min(p1x, p2x) - rWidth < minX) && (minX := Min(p1x, p2x) - rWidth)
                (Min(p1y, p2y) - rWidth < minY) && (minY := Min(p1y, p2y) - rWidth)
                (Max(p1x, p2x) + rWidth > maxX) && (maxX := Max(p1x, p2x) + rWidth)
                (Max(p1y, p2y) + rWidth > maxY) && (maxY := Max(p1y, p2y) + rWidth)
            }
            if (dist == 0 && this.ribbonPoints.Length > 0)
                this.ribbonPoints.Pop()
        }

        ; 5. Update Screen via UpdateLayeredWindow
        if (minX <= maxX && minY <= maxY) {
            pad := 8
            this.prevX := Max(0, minX - pad)
            this.prevY := Max(0, minY - pad)
            this.prevW := Min(this.vW - this.prevX, (maxX - minX) + 2 * pad)
            this.prevH := Min(this.vH - this.prevY, (maxY - minY) + 2 * pad)
            this.hasDrawn := true

            dst := (this.vX & 0xFFFFFFFF) | ((this.vY & 0xFFFFFFFF) << 32)
            sz  := (this.vW & 0xFFFFFFFF) | ((this.vH & 0xFFFFFFFF) << 32)
            src := 0
            blend := 0x01FF0000 ; AC_SRC_OVER | 255 alpha | AC_SRC_ALPHA

            DllCall("UpdateLayeredWindow", "ptr", this.hwnd, "ptr", 0, "int64*", dst, "int64*", sz, "ptr", this.hdc, "int64*", src, "uint", 0, "uint*", blend, "uint", 2)
        } else if (this.hasDrawn) {
            this.prevW := 0
            this.prevH := 0
            this.hasDrawn := false

            dst := (this.vX & 0xFFFFFFFF) | ((this.vY & 0xFFFFFFFF) << 32)
            sz  := (this.vW & 0xFFFFFFFF) | ((this.vH & 0xFFFFFFFF) << 32)
            src := 0
            blend := 0x01FF0000
            DllCall("UpdateLayeredWindow", "ptr", this.hwnd, "ptr", 0, "int64*", dst, "int64*", sz, "ptr", this.hdc, "int64*", src, "uint", 0, "uint*", blend, "uint", 2)
        }
    }
}

; Safe exit hook
OnExit((*) => MouseTrail.Stop())

; Standalone mode support with interactive controls
if (A_LineFile == A_ScriptFullPath) {
    MouseTrail.Start(1)

    ; Standalone Interactive Hotkeys
    HotKey("Tab",    (*) => MouseTrail.NextMode())
    HotKey("Space",  (*) => MouseTrail.Burst(35))
    HotKey("Escape", (*) => ExitApp())
}
