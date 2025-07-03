#Requires AutoHotkey v2.0

Persistent
#SingleInstance Force

; 引入模块和工具函数
#Include "modules/WindowVisibilityController.ahk"
#Include "modules/RenameWindowHandler.ahk"
#Include "utils/WindowUtils.ahk"

OnExit(ForceExit)
SetTitleMatchMode(2)
DetectHiddenWindows(true)
SetWinDelay(10)
SetKeyDelay(0)
CoordMode('Mouse', 'Screen')

Sleep(2000)

global hwnd := GetExplorerHwnd("E:\")
global hide := true
global Exiting := false

MonitorGet 1, &left, &top, &right, &bottom
InitWindow(hwnd, right, bottom)

StartWindowVisibilityController(hwnd)
StartRenameWindowHandler()

Return

ForceExit(reason, code) {
    global Exiting := true
    UnhideAndExit()
}
