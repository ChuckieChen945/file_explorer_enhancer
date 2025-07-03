#Requires AutoHotkey v2.0

Persistent
#SingleInstance Force

OnExit(ForceExit)
SetTitleMatchMode(2)
DetectHiddenWindows(true)
SetWinDelay(10)
SetKeyDelay(0)
CoordMode('Mouse', 'Screen')

Sleep(2000)  ; 稳定桌面

global hwnd := GetExplorerHwnd("E:\")
global hide := true
global Exiting := false

MonitorGet 1, &left, &top, &right, &bottom
InitWindow(hwnd, right, bottom)

; 计时器管理窗口显示
SetTimer(() => CheckMouseProximity(hwnd), 300)
; 计时器监控重命名窗口
SetTimer(HandleRenameWindow, 300)

Return  ; 进入空循环由 SetTimer 控制

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

CheckMouseProximity(hwnd) {
    if !WinExist("ahk_id " hwnd)
        ExitApp()

    MouseGetPos(&x, &y)
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)

    if ShouldShowWindow(x, y, wx, wy, ww, wh) {
        WinShow(hwnd)
        WinActivate(hwnd)
        hide := false
    } else if !IsMouseInWindow(x, y, wx, wy, ww, wh) {
        WinHide(hwnd)
        if WinActive(hwnd)
            Send('!{Esc}')
        hide := true
    }
}

ShouldShowWindow(x, y, wx, wy, ww, wh) {
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

GetExplorerHwnd(path := "E:\") {
    ; 创建 Shell.Application COM 对象
    explorer := ComObject("Shell.Application")
    explorer.Open(path)

    Sleep 500  ; 等待窗口创建

    windows := explorer.Windows
    needle := "file:///" StrReplace(path, "\", "/")

    ; 保证路径末尾有斜杠（与 LocationURL 匹配）
    if SubStr(needle, -1) != "/"
        needle .= "/"

    Loop windows.Count {
        win := windows.Item(A_Index - 1)
        if InStr(win.FullName, "explorer.exe") && InStr(win.LocationURL, needle) {
            return win.HWND
        }
    }
    return 0
}
