; -*- coding: utf-8-bom -*-

; TODO:用autohotkey v2重写
#Persistent
OnExit, ForceExit ;当脚本退出时，ForceExit 子例程会被调用
SetTitleMatchMode, 2  ; 设置标题匹配模式为包含模式
DetectHiddenWindows, on ;允许 AutoHotkey 脚本识别和操作那些在任务栏或常规窗口列表中不可见的窗口（如最小化的窗口）
#SingleInstance Force ;强制脚本只运行一个实例。
SetWinDelay 10 ;控制每次窗口操作（如 WinActivate、WinClose 等）之间的延迟时间，以毫秒为单位
SetKeyDelay 0 ;控制每个按键之间的延迟时间，单位为毫秒。这里设置为 0，表示键盘输入不应有延迟。
; Coordmode Mouse ;此处将鼠标坐标的参考模式设置为 屏幕坐标模式
CoordMode, Mouse, Screen
; CoordMode, ToolTip, Screen

; 启动并隐藏
Run, explorer.exe
WinActivate ; 激活窗口
WinWaitActive, ahk_class CabinetWClass
WinGet, hwnd, ID, ahk_class CabinetWClass
SysGet, Monitor1, Monitor, 1  ; 获取第一个显示器的属性
WinMove, ahk_id %hwnd%, , -10, 0, % ( Monitor1Right / 2 ) + 20, % Monitor1Bottom + 10
winHide % "ahk_id " . hwnd
ifwinactive % "ahk_id " . hwnd
	send !{esc}
hide := 1
EdgeWidth := 10  ; 边缘范围宽度
Exiting := 0 ;表示脚本未退出

; 监视鼠标位置并显示/隐藏
SetTimer, CheckMouse, 300

While, 1
{
    WinWaitActive, 重命名 ahk_class #32770
    send y
}


CheckMouse:
	MouseGetPos, MouseX, MouseY  ; 获取鼠标当前位置

	wingetpos, x, y, Width, Height, % "ahk_id " . hwnd
	if x < 0
		x = 0
	if y < 0
		y = 0
	; 用于调试
	; ToolTip, mouse: %MouseX%x%MouseY%`nwindow: %x%x%y% size: %Width%x%Height%`n%Monitor1Right%x%Monitor1Bottom%

	; 获取屏幕宽度并定义左侧边缘的区域

	if hide{
		; 检查鼠标是否靠近屏幕左侧
		if (MouseX < EdgeWidth)
		{
			WinShow % "ahk_id " . hwnd
			WinActivate % "ahk_id " . hwnd
			hide := 0
		}
	}
	else{
		if (MouseX <= x + Width)
			if (y <= MouseY) and (MouseY <= y + Height)
				return
		WinHide % "ahk_id " . hwnd
		ifwinactive % "ahk_id " . hwnd
			send !{esc}
		hide := 1
	}

return

ForceExit:
	Exiting := 1
	goto UnhideAll
return

UnhideAll:
	winshow % "ahk_id " . hwnd
	winactivate % "ahk_id " . hwnd
	if Exiting
		exitapp
return
