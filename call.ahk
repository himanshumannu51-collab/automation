#SingleInstance Force
#NoEnv
CoordMode, Mouse, Screen
SendMode Input
SetBatchLines -1
SetKeyDelay, 30, 30
SetWinDelay, 50

; ═══════════════════════════════════════
; COORDINATES — edit positions here only
; ═══════════════════════════════════════
global LEAD_X    := 273   , ROW1_Y   := 283  , ROW_GAP := 30
global AVATAR_X  := 106   , AVATAR_Y := 249
global EMAIL_X   := 224   , EMAIL_Y  := 476
global ICON2_X   := 926   , ICON2_Y  := 276
global TMPL_X    := 267   , TMPL_Y   := 600
global SELECT_X  := 412   , SELECT_Y := 285
global SEND_X    := 460   , SEND_Y   := 365
global CLOSE_X   := 403   , CLOSE_Y  := 649
global SCROLL_X  := 600   , SCROLL_Y := 500  , SCROLL_N := 6

; ═══════════════════════════════════════
; TIMING (400) — edit delays here only
; ═══════════════════════════════════════
; --- early steps (normal pace) ---
global T_SETTLE     := 600    ; before clicking lead
global T_PAGE       := 6000    ; page load after click
global T_HOVER_IN   := 1000     ; after reaching avatar
global T_POPUP      := 1200     ; hover popup appears
global T_ICON2      := 2000    ; wait after 926,276 click before email compose loads
global T_EMAIL_LOAD := 5000    ; email compose load
global T_SCROLL     := 800    ; after scroll settle

; --- send flow (50% slower) ---
global T_TMPL_OPEN  := 2400    ; template dropdown open
global T_TMPL_SELECT:= 1200    ; after selecting template
global T_PRE_SEND   := 1100     ; settle before send click
global T_AFTER_SEND := 400     ; confirm send completes
global T_PRE_CLOSE  := 400     ; settle before close
global T_AFTER_CLOSE:= 6000    ; after closing modal
global T_AFTER_TAB  := 1000    ; after closing tab

; mouse speeds: lower = faster
global SPD_SLOW     := 14      ; human hover
global SPD_MED      := 8       ; normal moves
global SPD_CHILL    := 12      ; send flow (relaxed)
global SPD_FAST     := 4       ; utility moves

; ═══════════════════════════════════════
; STATE
; ═══════════════════════════════════════
global Running := false
global Paused  := false
global Total   := 0

; ═══════════════════════════════════════
; HOTKEYS
; ═══════════════════════════════════════
F1::
    Running := true
    Paused  := false
    Total   := 0
    Tip("STARTED")
    MainLoop()
return

F2::
    if (!Running)
        return
    Paused := !Paused
    Tip(Paused ? "PAUSED  (F2 resume)" : "RESUMED")
return

Esc::
    Running := false
    Paused  := false
    Tip("STOPPED")
    SetTimer, TipOff, -2000
return

]::ExitApp

; ═══════════════════════════════════════
; CORE HELPERS
; ═══════════════════════════════════════
Wait(ms) {
    global Running, Paused
    end := A_TickCount + ms
    while (A_TickCount < end) {
        Sleep 25
        while (Paused && Running)
            Sleep 80
        if (!Running)
            return 0
    }
    return 1
}

R(lo, hi) {
    Random, v, %lo%, %hi%
    return v
}

M(x, y, s := 8) {
    MouseMove, %x%, %y%, %s%
}

Tip(t) {
    global Total
    ToolTip, [#%Total%] %t%, 10, 5
}

TipOff:
    ToolTip
return

; ═══════════════════════════════════════
; MAIN LOOP
; ═══════════════════════════════════════
MainLoop() {
    global

    while (Running) {
        Loop 10 {
            if (!Running)
                return
            Total++
            Tip("ROW " . A_Index . "/10")
            if (!DoLead(A_Index))
                return
        }
        Tip("SCROLL")
        M(SCROLL_X, SCROLL_Y, SPD_FAST)
        if (!Wait(200))
            return
        Send {WheelDown %SCROLL_N%}
        if (!Wait(T_SCROLL))
            return
    }
}

; ═══════════════════════════════════════
; PROCESS ONE LEAD
; ═══════════════════════════════════════
DoLead(row) {
    global

    y := ROW1_Y + ((row - 1) * ROW_GAP)

    ; 1 — CLICK LEAD (273, rowY)
    M(LEAD_X, y, SPD_MED)
    if (!Wait(T_SETTLE))
        return 0
    Click
    if (!Wait(R(100, 180)))
        return 0

    ; 2 — PAGE LOAD
    if (!Wait(T_PAGE + R(-500, 800)))
        return 0

    ; 3 — HOVER AVATAR (106, 249) — slow, human-like
    M(AVATAR_X, AVATAR_Y, SPD_SLOW)
    if (!Wait(T_HOVER_IN + R(0, 200)))
        return 0
    if (!Wait(T_POPUP + R(0, 300)))
        return 0

    ; 4 — CLICK EMAIL ICON on popup (224, 476)
    M(EMAIL_X, EMAIL_Y, SPD_MED)
    if (!Wait(R(250, 450)))
        return 0
    Click
    if (!Wait(R(100, 180)))
        return 0

    ; 4.5 — CLICK (926, 277) after email icon
    M(926, 277, SPD_MED)
    if (!Wait(R(200, 400)))
        return 0
    Click
    if (!Wait(R(150, 300)))
        return 0

    ; 5 — CLICK SECOND ICON (926, 276) then 2 sec settle
    M(ICON2_X, ICON2_Y, SPD_MED)
    if (!Wait(R(200, 400)))
        return 0
    Click
    if (!Wait(T_ICON2 + R(0, 300)))
        return 0

    ; 6 — EMAIL COMPOSE LOAD (4-6s)
    if (!Wait(T_EMAIL_LOAD + R(-1000, 1000)))
        return 0

    ; ─── SEND FLOW (RELAXED PACE) ────────────

    ; 7 — CLICK TEMPLATE BUTTON (267, 600)
    M(TMPL_X, TMPL_Y, SPD_CHILL)
    if (!Wait(R(400, 650)))
        return 0
    Click
    if (!Wait(T_TMPL_OPEN + R(0, 300)))
        return 0

    ; 8 — SELECT TEMPLATE (412, 285)
    M(SELECT_X, SELECT_Y, SPD_CHILL)
    if (!Wait(R(500, 800)))
        return 0
    Click
    if (!Wait(T_TMPL_SELECT + R(0, 300)))
        return 0

    ; 9 — SEND (460, 365)
    M(SEND_X, SEND_Y, SPD_CHILL)
    if (!Wait(T_PRE_SEND + R(0, 300)))
        return 0
    Click
    if (!Wait(T_AFTER_SEND))
        return 0

    ; 10 — CLOSE MODAL (403, 649)
    M(CLOSE_X, CLOSE_Y, SPD_CHILL)
    if (!Wait(T_PRE_CLOSE + R(0, 300)))
        return 0
    Click
    if (!Wait(T_AFTER_CLOSE))
        return 0

    ; 11 — CLOSE TAB
    Send ^w
    if (!Wait(T_AFTER_TAB + R(0, 300)))
        return 0

    return 1
}
