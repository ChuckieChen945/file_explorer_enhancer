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
global isHide := false
global Exiting := false
global OneCmdHwnd := 0
global OneCmdPid := 0

Run('notepad.exe')

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
    WinMove(-10, 0, (screenW / 2) + 20, screenH + 10, OneCmdHwnd)
    WinHide(OneCmdHwnd)
    if WinActive(OneCmdHwnd)
        Send('!{Esc}')
    global isHide := true
}

CheckMouseProximity() {
    UpdateOneCommanderHandles()
    if (!OneCmdHwnd) {
        return
    }

    MouseGetPos(&x, &y, &hoverHwnd)
    hoverPid := WinGetPID("ahk_id " hoverHwnd)

    if IsMouseInToggleRegion(x, y) {
        try {
            WinShow(OneCmdHwnd)
            WinActivate(OneCmdHwnd)
            global isHide := false
        } catch Error as e {
        }

    }
    else if (hoverPid != OneCmdPid) {
        try {
            WinHide(OneCmdHwnd)
            if WinActive(OneCmdHwnd)
                Send('!{Esc}')
            global isHide := true
        } catch Error as e {
        }
    }
}

IsMouseInToggleRegion(x, y) {
    return isHide && x < 2 && y < 200
}

HandleExit(reason, code) {
    global Exiting := true
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

    if (!OneCmdPid) {
        winList := WinGetList("ahk_exe" . ProcessName)
        global OneCmdHwnd := winList.Length >= 1 ? winList[1] : 0
        global OneCmdPid := OneCmdHwnd ? WinGetPID(OneCmdHwnd) : 0
        if OneCmdPid {
            InitOneCommanderWindow()
        }
    }
    else if (!ProcessExist(OneCmdPid)) {
        global OneCmdHwnd := 0
        global OneCmdPid := 0
        global isHide := false
    }

}
