#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ========== 初始化 ==========
InitApp()

; ========== 定时器注册 ==========
SetTimer(CheckMouseProximity, 300)
SetTimer(HandleRenameDialog, 300)

return

; ========== 初始化函数 ==========
InitApp() {
    global AppState := {
        IsHidden: false,
        Exiting: false,
        OneCmdHwnd: 0,
        OneCmdPid: 0,
        TargetProcess: "onecommander.exe"
    }

    OnExit(HandleExit)
    SetTitleMatchMode(2)
    DetectHiddenWindows(true)
    SetWinDelay(10)
    SetKeyDelay(0)
    CoordMode("Mouse", "Screen")

    Run(AppState.TargetProcess)
    Sleep(5000)
    UpdateTargetWindowHandles()
    InitTargetWindow()
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
        found := false

        for hwnd in hwndList {
            try {
                style := WinGetStyle(hwnd)

                if (style & 0x10000000) {

                    AppState.OneCmdHwnd := hwnd
                    AppState.OneCmdPid := WinGetPID(hwnd)

                    found := true
                    break
                }
            } catch {
                continue
            }
        }

        ; 如果没有找到匹配窗口，清空状态
        if !found {
            AppState.OneCmdHwnd := 0
            AppState.OneCmdPid := 0
        }

    } else if !ProcessExist(AppState.OneCmdPid) {
        ResetTargetState()
    }
}

InitTargetWindow() {
    MonitorGet(1, , , &screenW, &screenH)
    ; 这一行报错：Error: Target window not found.
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
