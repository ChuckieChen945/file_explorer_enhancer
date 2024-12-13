#Requires AutoHotkey v2.0

Persistent
OnExit(ForceExit) ; When the script exits, ForceExit subroutine is called
SetTitleMatchMode(2)  ; Set title match mode to "contains"
DetectHiddenWindows(true) ; Allow AHK to detect hidden windows (e.g., minimized ones)
#SingleInstance Force
SetWinDelay(10) ; Set the delay between window operations (in milliseconds)
SetKeyDelay(0) ; Set no delay between key presses
CoordMode('Mouse', 'Screen') ; Set mouse coordinates mode to screen

app := A_WinDir '\explorer.exe'  ; 定义 Explorer 可执行文件的路径
winTitle := 'ahk_exe' app            ; 设置窗口标题（基于可执行文件的路径）
hwnd := WinWaitActive(winTitle)  ; 等待窗口变为活动状态，并将其句柄存入 hWnd
MonitorGet 1, &L, &T, &R, &B
WinMove(-10, 0, (R / 2) + 20, B + 10,winTitle)
WinHide(hwnd)
if WinActive(hwnd) {
    Send('!{Esc}')
}
hide := 1
EdgeWidth := 10  ; Edge width for detecting mouse proximity
Exiting := 0  ; Flag to indicate the script is not exiting

; Monitor mouse position and show/hide window
SetTimer(CheckMouse, 300)

while (true) {
    WinWaitActive('重命名 ahk_class #32770')
    Send('y')
}

CheckMouse() {
    MouseGetPos(&MouseX, &MouseY) ; Get the mouse position

    global hwnd
    WinGetPos(&x, &y, &Width, &Height, hwnd)
    if (x < 0) {
        x := 0
    }
    if (y < 0) {
        y := 0
    }

    ; Debugging information
    global R
    global B
    ToolTip("mouse: " MouseX "x" MouseY "`nwindow: " x "x" y " size: " Width "x" Height "`n" R "x" B "`n编码测试" )

    ; Detect if the mouse is close to the left edge of the screen
    global hide
    global EdgeWidth
    global Exiting
    if (hide) {
        if (MouseX < EdgeWidth) {
            WinShow(hwnd)
            WinActivate(hwnd)
            hide := 0
        }
    } else {
        if (MouseX <= x + Width && MouseY >= y && MouseY <= y + Height) {
            return
        }
        WinHide(hwnd)
        if WinActive(hwnd) {
            Send('!{Esc}')
        }
        hide := 1
    }
}

ForceExit(ExitReason, ExitCode) {
    global Exiting
    Exiting := 1
    UnhideAll()
}

UnhideAll() {
    WinShow(hwnd)
    WinActivate(hwnd)
    global Exiting
    if (Exiting) {
        ExitApp()
    }
}
