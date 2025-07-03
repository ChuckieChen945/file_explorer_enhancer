StartRenameWindowHandler() {
    SetTimer(HandleRenameWindow, 300)
}

HandleRenameWindow() {
    if WinActive("重命名 ahk_class #32770") {
        Send('y')
    }
}
