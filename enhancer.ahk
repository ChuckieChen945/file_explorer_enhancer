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
        TargetProcess: "onecommander.exe",
        TargetMonitor: 2   ; 默认放在主显示器，您可改为 2、3...
    }

    OnExit(HandleExit)
    SetTitleMatchMode(2)
    DetectHiddenWindows(true)
    SetWinDelay(10)
    SetKeyDelay(0)
    CoordMode("Mouse", "Screen")

    hwndList := WinGetList("ahk_exe " . AppState.TargetProcess)

    if hwndList.Length == 0 {
        Run(AppState.TargetProcess)
        Sleep(5000)
        UpdateTargetWindowHandles()
        InitTargetWindow()
    }
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

    try {
        MouseGetPos(&x, &y, &hoverHwnd)
        hoverPid := WinGetPID("ahk_id " hoverHwnd)

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
    ; 限定到目标显示器边缘
    mon := GetMonitorBounds(AppState.TargetMonitor)
    return AppState.IsHidden && x >= mon.Left && x < mon.Left + 2 && y >= mon.Top && y < mon.Top + 200
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

        if !found {
            AppState.OneCmdHwnd := 0
            AppState.OneCmdPid := 0
        }

    } else if !ProcessExist(AppState.OneCmdPid) {
        ResetTargetState()
    }
}

InitTargetWindow() {
    mon := GetMonitorBounds(AppState.TargetMonitor)

    try {
        WinMove(mon.Left - 10, mon.Top, (mon.Right - mon.Left) / 2 + 20, (mon.Bottom - mon.Top) + 10, AppState.OneCmdHwnd
        )
        WinHide(AppState.OneCmdHwnd)
        if WinActive(AppState.OneCmdHwnd)
            Send("!{Esc}")
        AppState.IsHidden := true
    } catch {
        MsgBox("Error: Target window not found or cannot be moved.")
    }
}

ResetTargetState() {
    AppState.OneCmdHwnd := 0
    AppState.OneCmdPid := 0
    AppState.IsHidden := false
}

; ========== 工具函数 ==========
GetMonitorBounds(n) {
    if (n < 1 || n > MonitorGetCount())
        n := 1
    MonitorGet(n, &l, &t, &r, &b)
    return { Left: l, Top: t, Right: r, Bottom: b }
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
