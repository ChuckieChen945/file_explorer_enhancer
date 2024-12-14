#Requires AutoHotkey v2.0

Persistent
OnExit(ForceExit) ; When the script exits, ForceExit subroutine is called
SetTitleMatchMode(2)  ; Set title match mode to "contains"
DetectHiddenWindows(true) ; Allow AHK to detect hidden windows (e.g., minimized ones)
#SingleInstance Force
SetWinDelay(10) ; Set the delay between window operations (in milliseconds)
SetKeyDelay(0) ; Set no delay between key presses
CoordMode('Mouse', 'Screen') ; Set mouse coordinates mode to screen

; Initialize script settings
app := A_WinDir '\explorer.exe'  ; 定义 Explorer 可执行文件的路径
winTitle := 'ahk_exe' app            ; 设置窗口标题（基于可执行文件的路径）
run app
hwnd := WinWaitActive(winTitle)  ; 等待窗口变为活动状态，并将其句柄存入 hWnd
hide := true
Exiting := 0  ; Flag to indicate the script is not exiting

MonitorGet 1, &left, &top, &right, &bottom
initWindow(winTitle, right, bottom)

; Monitor mouse position and show/hide window
SetTimer(CheckMouseProximity.Bind(hwnd), 300)

while (true) {
    ; Handle rename window actions
    HandleRenameWindow()
}

; ---------------------------------------------------------
; Function Definitions

HandleRenameWindow() {
    WinWaitActive('重命名 ahk_class #32770')
    Send('y')
}

initWindow(winTitle, right, bottom) {

    ; hwnd := WinWaitActive(winTitle)  ; 等待窗口变为活动状态，并将其句柄存入 hWnd
    WinMove(-10, 0, (right / 2) + 20, bottom + 10, hwnd)
    WinHide(hwnd)
    if WinActive(hwnd) {
        Send('!{Esc}')
    }
}

CheckMouseProximity(hwnd) {

    if !WinExist('ahk_id ' hwnd) {
        ExitApp()
    }

    MouseGetPos(&MouseX, &MouseY) ; Get the mouse position

    WinGetPos(&windowX, &windowY, &windowWidth, &windowHeight, hwnd)
    windowX := Max(windowX, 0)
    windowY := Max(windowY, 0)

    ; Check mouse proximity to the left edge and handle window visibility
    ManageWindowVisibility(MouseX, MouseY, windowX, windowY, windowWidth, windowHeight, hwnd)

    ; Debugging information
    ; global right
    ; global bottom
    ; global hide
    ; ToolTip("mouse: " MouseX "x" MouseY "`nwindow: " windowX "x" windowY " size: " windowWidth "x" windowHeight "`n" right "x" bottom "`n编码测试" "`nhide:" hide
    ; )

}

ManageWindowVisibility(MouseX, MouseY, windowX, windowY, windowWidth, windowHeight, hwnd) {
    ; Detect if the mouse is close to the left edge of the screen
    global hide
    static EdgeWidth := 10  ; Edge width for detecting mouse proximity

    if (hide && MouseX < EdgeWidth) {
        WinShow(hwnd)
        WinActivate(hwnd)
        hide := false
    } else {
        if (MouseX <= windowX + windowWidth && MouseY >= windowY && MouseY <= windowY + windowHeight) {
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
