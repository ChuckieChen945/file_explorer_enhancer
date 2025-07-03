#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ========== 初始化 ==========
InitApp()

; ========== 定时器注册 ==========
; 1437 1750
SetTimer(CheckMouseProximity, 1650)
SetTimer(HandleRenameDialog, 300)

return

; ========== 初始化函数 ==========
InitApp() {
    global AppState := {
        IsHidden: false,
        Exiting: false,
        OneCmdHwnd: 0,
        OneCmdPid: 0,
        TargetProcess: "notepad.exe"
    }

    OnExit(HandleExit)
    SetTitleMatchMode(2)
    DetectHiddenWindows(true)
    SetWinDelay(10)
    SetKeyDelay(0)
    CoordMode("Mouse", "Screen")

    Run(AppState.TargetProcess)
}

; ========== 主逻辑处理函数 ==========

HandleRenameDialog() {
    if WinActive("重命名 ahk_class #32770") {
        Send("y")
    }
}

CheckMouseProximity() {
    UpdateTargetWindowHandles()

    if !AppState.OneCmdHwnd
        return

    MouseGetPos(&x, &y, &hoverHwnd)
    hoverPid := WinGetPID("ahk_id " hoverHwnd)

    try {
        if ShouldShowTarget(x, y) {
            ShowTargetWindow()
        } else if hoverPid != AppState.OneCmdPid {
            HideTargetWindow()
        }
    } catch {
        ; 忽略错误
    }
}

; ========== 状态处理函数 ==========

ShouldShowTarget(x, y) {
    return AppState.IsHidden && x < 2 && y < 200
}

ShowTargetWindow() {
    WinShow(AppState.OneCmdHwnd)
    WinActivate(AppState.OneCmdHwnd)
    AppState.IsHidden := false
}

HideTargetWindow() {
    WinHide(AppState.OneCmdHwnd)
    if WinActive(AppState.OneCmdHwnd)
        Send("!{Esc}")
    AppState.IsHidden := true
}

UpdateTargetWindowHandles() {
    if !AppState.OneCmdPid {
        hwndList := WinGetList("ahk_exe " . AppState.TargetProcess)
        AppState.OneCmdHwnd := hwndList.Length >= 1 ? hwndList[1] : 0
        AppState.OneCmdPid := AppState.OneCmdHwnd ? WinGetPID(AppState.OneCmdHwnd) : 0

        if AppState.OneCmdPid {
            InitTargetWindow()
        }
    } else if !ProcessExist(AppState.OneCmdPid) {
        ResetTargetState()
    }
}

InitTargetWindow() {
    MonitorGet(1, , , &screenW, &screenH)
    WinMove(-10, 0, screenW / 2 + 20, screenH + 10, AppState.OneCmdHwnd)
    WinHide(AppState.OneCmdHwnd)
    if WinActive(AppState.OneCmdHwnd)
        Send("!{Esc}")
    AppState.IsHidden := true
}

ResetTargetState() {
    AppState.OneCmdHwnd := 0
    AppState.OneCmdPid := 0
    AppState.IsHidden := false
}

; ========== 退出处理函数 ==========

HandleExit(Reason, Code) {
    AppState.Exiting := true
    ExitGracefully()
}

ExitGracefully() {
    if AppState.OneCmdHwnd {
        WinShow(AppState.OneCmdHwnd)
        WinActivate(AppState.OneCmdHwnd)
    }
    ExitApp()
}
