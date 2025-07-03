#Requires AutoHotkey v2.0

Persistent
#SingleInstance Force

OnExit(ForceExit)
SetTitleMatchMode(2)
DetectHiddenWindows(true)
SetWinDelay(10)
SetKeyDelay(0)
CoordMode('Mouse', 'Screen')

Run('D:\scoop\apps\onecommander\current\OneCommander.exe')
Sleep(5000)
hwndAndPid := GetOnecommanderHwndAndPid()
hwnd := hwndAndPid[1]
global hide := true
global Exiting := false

MonitorGet 1, &left, &top, &right, &bottom
InitWindow(hwnd, right, bottom)

; 计时器管理窗口显示
SetTimer(CheckMouseProximity, 300)
; 计时器监控重命名窗口
SetTimer(HandleRenameWindow, 300)

return  ; 进入空循环由 SetTimer 控制

; ---------- Function Definitions ----------

HandleRenameWindow() {
    if WinActive("重命名 ahk_class #32770") {
        Send('y')
    }
}

InitWindow(hwnd, screenW, screenH) {
    WinMove(-10, 0, (screenW / 2) + 20, screenH + 10, hwnd)
    WinHide(hwnd)
    if WinActive(hwnd)
        Send('!{Esc}')
}

CheckMouseProximity() {

    temp := GetOnecommanderHwndAndPid()
    hwnd := temp[1]
    pid := temp[2]

    if !WinExist("ahk_id " hwnd)
        return

    ; 获取鼠标指针下的窗口句柄
    MouseGetPos(&x, &y, &active_hwnd)
    ; 获取该窗口对应的 PID
    active_pid := WinGetPID("ahk_id " active_hwnd)

    Tooltip(
        "Mouse: (" x ", " y ")\n"
        "UnderMouse HWND: " active_hwnd "\n"
        "UnderMouse PID: " active_pid "\n"
        "Target HWND: " hwnd "\n"
        "Target PID: " pid
    )
    WinGetPos(&wx, &wy, &ww, &wh, active_hwnd)

    if IsMouseInActiveRegion(x, y) {
        WinShow(hwnd)
        WinActivate(hwnd)
        hide := false
    }
    else if (active_pid != pid) {
        ; if !IsMouseInWindow(x, y, wx, wy, ww, wh) {
        WinHide(hwnd)
        if WinActive(hwnd)
            Send('!{Esc}')
        hide := true
        ; }

    }
}

IsMouseInActiveRegion(x, y) {
    return hide && x < 2 && y < 200
}

IsMouseInWindow(x, y, wx, wy, ww, wh) {
    return (x >= wx && x <= wx + ww && y >= wy && y <= wy + wh)
}

ForceExit(reason, code) {
    global Exiting := true
    UnhideAndExit()
}

UnhideAndExit() {
    global hwnd
    WinShow(hwnd)
    WinActivate(hwnd)
    if Exiting
        ExitApp()
}

GetOnecommanderHwndAndPid() {

    ProcessName := "OneCommander.exe"
    pid := ProcessExist(ProcessName)
    if pid {
        hwnd := WinGetID("ahk_exe " . ProcessName)
        if hwnd {
            return [hwnd, pid]
        }
    }
    else {
        return [0, 0]
    }
}
