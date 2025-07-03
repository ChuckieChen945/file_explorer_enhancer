#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ---------- 全局设置 ----------
OnExit(HandleExit)
SetTitleMatchMode(2)
DetectHiddenWindows(true)
SetWinDelay(10)
SetKeyDelay(0)
CoordMode('Mouse', 'Screen')

; ---------- 全局状态对象 ----------
global State := {
    IsHidden: false,
    Exiting: false,
    OneCmdHwnd: 0,
    OneCmdPid: 0,
    TargetProcess: "notepad.exe"
}

; ---------- 启动 ----------
Run(State.TargetProcess)

; ---------- 定时器 ----------
SetTimer(CheckMouseProximity, 3000)
SetTimer(HandleRenameDialog, 300)

return

; ===============================
;         函数定义区域
; ===============================

HandleRenameDialog() {
    if WinActive("重命名 ahk_class #32770") {
        Send('y')
    }
}

InitOneCommanderWindow() {
    MonitorGet(1, , , &screenW, &screenH)
    WinMove(-10, 0, screenW / 2 + 20, screenH + 10, State.OneCmdHwnd)
    WinHide(State.OneCmdHwnd)
    if WinActive(State.OneCmdHwnd)
        Send('!{Esc}')
    State.IsHidden := true
}

CheckMouseProximity() {
    UpdateOneCommanderHandles()
    if !State.OneCmdHwnd
        return

    MouseGetPos(&x, &y, &hoverHwnd)
    hoverPid := WinGetPID("ahk_id " hoverHwnd)

    try {
        if IsMouseInToggleRegion(x, y) {
            WinShow(State.OneCmdHwnd)
            WinActivate(State.OneCmdHwnd)
            State.IsHidden := false
        }
        else if hoverPid != State.OneCmdPid {
            WinHide(State.OneCmdHwnd)
            if WinActive(State.OneCmdHwnd)
                Send('!{Esc}')
            State.IsHidden := true
        }
    } catch Error {
        ; 忽略错误
    }
}

IsMouseInToggleRegion(x, y) {
    return State.IsHidden && x < 2 && y < 200
}

HandleExit(reason, code) {
    State.Exiting := true
    ExitGracefully()
}

ExitGracefully() {
    if State.OneCmdHwnd {
        WinShow(State.OneCmdHwnd)
        WinActivate(State.OneCmdHwnd)
    }
    ExitApp()
}

UpdateOneCommanderHandles() {
    if !State.OneCmdPid {
        winList := WinGetList("ahk_exe " . State.TargetProcess)
        State.OneCmdHwnd := winList.Length >= 1 ? winList[1] : 0
        State.OneCmdPid := State.OneCmdHwnd ? WinGetPID(State.OneCmdHwnd) : 0
        if State.OneCmdPid {
            InitOneCommanderWindow()
        }
    }
    else if !ProcessExist(State.OneCmdPid) {
        State.OneCmdHwnd := 0
        State.OneCmdPid := 0
        State.IsHidden := false
    }
}
