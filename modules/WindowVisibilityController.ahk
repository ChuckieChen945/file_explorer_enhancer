StartWindowVisibilityController(hwnd) {
    SetTimer(() => CheckMouseProximity(hwnd), 300)
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

