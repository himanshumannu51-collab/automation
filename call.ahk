; ============================================================
;  CALL LOOP v8
;  F1 = Start | F2 = Pause/Resume | F3 = Stop
; ============================================================

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
CoordMode, Click, Screen
SetBatchLines, -1
#MaxThreadsPerHotkey 1

; ─────────────────────────────────────
;  CONFIG
; ─────────────────────────────────────
global CallIconX  := 1046
global RowStartY  := 283
global RowStep    := 34
global MakeCallX  := 759
global MakeCallY  := 216
global CutCallX   := 1072
global CutCallY   := 406
global CloseBoxX  := 1296
global CloseBoxY  := 140
global MaxRows    := 20

; ─────────────────────────────────────
;  STATE
; ─────────────────────────────────────
global S          := "IDLE"
global Row        := 1
global Ticks      := 0
global PrevState  := ""
global MouseRefX  := 0
global MouseRefY  := 0
global ActionDone := 0

; ─────────────────────────────────────
;  HOTKEYS
; ─────────────────────────────────────

F1::
    SetTimer, ENGINE, Off
    S          := "IDLE"
    Row        := 1
    Ticks      := 0
    ActionDone := 0
    PrevState  := ""
    ToolTip, [ROW 1] Starting in 1s — don't move mouse
    Sleep, 1000
    MouseGetPos, MouseRefX, MouseRefY
    S := "DIAL"
    SetTimer, ENGINE, 100
return

F2::
    if (S = "PAUSED") {
        S := PrevState
        ToolTip, [RESUMED] Row %Row% — %S%
    } else if (S != "IDLE") {
        PrevState := S
        S := "PAUSED"
        ToolTip, [PAUSED] F2=Resume  F3=Stop
    }
return

F3::
    SetTimer, ENGINE, Off
    S          := "IDLE"
    ActionDone := 0
    PrevState  := ""
    ToolTip, [STOPPED] F1 to restart
    SetTimer, CLEAR_TIP, -2000
return

CLEAR_TIP:
    ToolTip
return

; ─────────────────────────────────────
;  ENGINE — 100ms tick
; ─────────────────────────────────────
ENGINE:
    Critical
    if (S = "IDLE" || S = "PAUSED")
        return

    ; ── MOUSE GUARD ──────────────────
    MouseGetPos, MX, MY
    if (MX != MouseRefX || MY != MouseRefY) {
        SetTimer, ENGINE, Off
        S          := "IDLE"
        ActionDone := 0
        ToolTip, [STOPPED] Mouse moved — F1 restart
        SetTimer, CLEAR_TIP, -2000
        return
    }

    ; ── ROW LIMIT ────────────────────
    if (Row > MaxRows) {
        SetTimer, ENGINE, Off
        S := "IDLE"
        ToolTip, [DONE] All %MaxRows% rows completed!
        SetTimer, CLEAR_TIP, -3000
        return
    }

    ; ════════════════════════════════
    ;  DIAL
    ;  Click call icon → wait 2s
    ; ════════════════════════════════
    if (S = "DIAL") {
        if (ActionDone = 0) {
            CallIconY := RowStartY + ((Row - 1) * RowStep)
            ToolTip, [ROW %Row%] Clicking call icon...
            MouseMove, %CallIconX%, %CallIconY%, 0
            DllCall("mouse_event", "uint", 0x02, "int", 0, "int", 0, "uint", 0, "ptr", 0)
            DllCall("mouse_event", "uint", 0x04, "int", 0, "int", 0, "uint", 0, "ptr", 0)
            MouseGetPos, MouseRefX, MouseRefY
            ActionDone := 1
            Ticks := 20                 ; 2s
        } else {
            Ticks--
            secs := (Ticks // 10) + 1
            ToolTip, [ROW %Row%] Dialer opening in %secs%s...
            if (Ticks <= 0) {
                ActionDone := 0
                S := "CONFIRM"
            }
        }
        return
    }

    ; ════════════════════════════════
    ;  CONFIRM
    ;  Click Make Call → wait 1s
    ; ════════════════════════════════
    if (S = "CONFIRM") {
        if (ActionDone = 0) {
            ToolTip, [ROW %Row%] Confirming Make Call...
            MouseMove, %MakeCallX%, %MakeCallY%, 0
            DllCall("mouse_event", "uint", 0x02, "int", 0, "int", 0, "uint", 0, "ptr", 0)
            DllCall("mouse_event", "uint", 0x04, "int", 0, "int", 0, "uint", 0, "ptr", 0)
            MouseGetPos, MouseRefX, MouseRefY
            ActionDone := 1
            Ticks := 10                 ; 1s
        } else {
            Ticks--
            secs := (Ticks // 10) + 1
            ToolTip, [ROW %Row%] Call connecting in %secs%s...
            if (Ticks <= 0) {
                ActionDone := 0
                Ticks := 350            ; 35s
                S := "WAIT_CUT"
            }
        }
        return
    }

    ; ════════════════════════════════
    ;  WAIT_CUT
    ;  35s countdown — then cut
    ; ════════════════════════════════
    if (S = "WAIT_CUT") {
        Ticks--
        secs := (Ticks // 10) + 1
        ToolTip, [ROW %Row%] Cutting call in %secs%s...
        if (Ticks <= 0) {
            ActionDone := 0
            S := "CUT"
        }
        return
    }

    ; ════════════════════════════════
    ;  CUT
    ;  Click cut → wait 7s → CLOSE
    ; ════════════════════════════════
    if (S = "CUT") {
        if (ActionDone = 0) {
            ToolTip, [ROW %Row%] Cutting call now...
            MouseMove, %CutCallX%, %CutCallY%, 0
            DllCall("mouse_event", "uint", 0x02, "int", 0, "int", 0, "uint", 0, "ptr", 0)
            DllCall("mouse_event", "uint", 0x04, "int", 0, "int", 0, "uint", 0, "ptr", 0)
            MouseGetPos, MouseRefX, MouseRefY
            ActionDone := 1
            Ticks := 70                 ; 7s
        } else {
            Ticks--
            secs := (Ticks // 10) + 1
            ToolTip, [ROW %Row%] Closing window in %secs%s...
            if (Ticks <= 0) {
                ActionDone := 0
                S := "CLOSE"
            }
        }
        return
    }

    ; ════════════════════════════════
    ;  CLOSE
    ;  Click close (1296,140) → wait 5s → next row
    ; ════════════════════════════════
    if (S = "CLOSE") {
        if (ActionDone = 0) {
            ToolTip, [ROW %Row%] Closing window...
            MouseMove, %CloseBoxX%, %CloseBoxY%, 0
            DllCall("mouse_event", "uint", 0x02, "int", 0, "int", 0, "uint", 0, "ptr", 0)
            DllCall("mouse_event", "uint", 0x04, "int", 0, "int", 0, "uint", 0, "ptr", 0)
            MouseGetPos, MouseRefX, MouseRefY
            ActionDone := 1
            Ticks := 50                 ; 5s
        } else {
            Ticks--
            secs := (Ticks // 10) + 1
            ToolTip, [ROW %Row%] Next row in %secs%s...
            if (Ticks <= 0) {
                Row++
                ActionDone := 0
                Ticks      := 0
                S          := "DIAL"
                ToolTip, [ROW %Row%] Starting...
            }
        }
        return
    }

return
