InitWindow(hwnd, screenW, screenH) {
    WinMove(-10, 0, (screenW / 2) + 20, screenH + 10, hwnd)
    WinHide(hwnd)
    if WinActive(hwnd)
        Send('!{Esc}')
}

UnhideAndExit() {
    global hwnd
    WinShow(hwnd)
    WinActivate(hwnd)
    if Exiting
        ExitApp()
}

GetExplorerHwnd(path := "E:\") {
    explorer := ComObject("Shell.Application")
    explorer.Open(path)
    Sleep 500

    windows := explorer.Windows
    needle := "file:///" StrReplace(path, "\", "/")
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
