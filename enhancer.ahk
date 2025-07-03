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

; ---------- 启动与初始化 ----------
global HideWindow := true
global Exiting := false
global OneCmdHwnd := 0
global OneCmdPid := 0

; Run('D:\scoop\apps\onecommander\current\OneCommander.exe')
Run('notepad.exe')
Sleep(5000)

UpdateOneCommanderHandles()
if (OneCmdHwnd) {
    MonitorGet(1, &left, &top, &right, &bottom)
    InitOneCommanderWindow(OneCmdHwnd, right, bottom)
}

; ---------- 定时器 ----------
SetTimer(CheckMouseProximity, 300)
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

InitOneCommanderWindow(hwnd, screenW, screenH) {
    WinMove(-10, 0, (screenW / 2) + 20, screenH + 10, hwnd)
    WinHide(hwnd)
    if WinActive(hwnd)
        Send('!{Esc}')
}

CheckMouseProximity() {
    UpdateOneCommanderHandles()
    if !WinExist("ahk_id " OneCmdHwnd)
        return

    MouseGetPos(&x, &y, &hoverHwnd)
    hoverPid := WinGetPID("ahk_id " hoverHwnd)

    ; Tooltip(
    ;     "Mouse: (" x ", " y ")\n"
    ;     "UnderMouse HWND: " hoverHwnd "\n"
    ;     "UnderMouse PID: " hoverPid "\n"
    ;     "Target HWND: " OneCmdHwnd "\n"
    ;     "Target PID: " OneCmdPid
    ; )

    if IsMouseInToggleRegion(x, y) {
        WinShow(OneCmdHwnd)
        WinActivate(OneCmdHwnd)
        HideWindow := false
    }
    else if (hoverPid != OneCmdPid) {
        WinHide(OneCmdHwnd)
        if WinActive(OneCmdHwnd)
            Send('!{Esc}')
        HideWindow := true
    }
}

IsMouseInToggleRegion(x, y) {
    return HideWindow && x < 2 && y < 200
}

HandleExit(reason, code) {
    Exiting := true
    ExitGracefully()
}

ExitGracefully() {
    if (OneCmdHwnd) {
        WinShow(OneCmdHwnd)
        WinActivate(OneCmdHwnd)
    }
    ExitApp()
}
UpdateOneCommanderHandles() {
    ProcessName := "notepad.exe"
    winList := WinGetList("ahk_exe " . ProcessName)
    global OneCmdHwnd := winList[1]
    global OneCmdPid := WinGetPID(OneCmdHwnd)

}
