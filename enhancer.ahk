#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ==============================================================================
; 全局配置
; ==============================================================================

class Config {
    static OneCmdProcess := "onecommander.exe"
    static EdgeProcess := "msedge.exe"
    static EdgeUrl := "https://gemini.google.com"
    static TargetMonitor := 0
    static CheckInterval := 300
    static EdgeHotkey := "#z"
    static StartupDelay := 2000
    static WindowReadyTimeout := 10
    static DebugMode := false

    static ConfigFile := "config.ini"
    static LogFile := "debug.log"

    static Load() {
        if !FileExist(this.ConfigFile) {
            this.Save()
            return
        }

        try {
            this.OneCmdProcess := IniRead(this.ConfigFile, "Settings", "OneCmdProcess", this.OneCmdProcess)
            this.EdgeProcess := IniRead(this.ConfigFile, "Settings", "EdgeProcess", this.EdgeProcess)
            this.EdgeUrl := IniRead(this.ConfigFile, "Settings", "EdgeUrl", this.EdgeUrl)
            this.TargetMonitor := Integer(IniRead(this.ConfigFile, "Settings", "TargetMonitor", this.TargetMonitor))
            this.EdgeHotkey := IniRead(this.ConfigFile, "Settings", "EdgeHotkey", this.EdgeHotkey)
            this.StartupDelay := Integer(IniRead(this.ConfigFile, "Settings", "StartupDelay", this.StartupDelay))
            this.WindowReadyTimeout := Integer(IniRead(this.ConfigFile, "Settings", "WindowReadyTimeout", this.WindowReadyTimeout
            ))
        }

        ; 自动选择显示器
        monCount := MonitorGetCount()
        if (this.TargetMonitor == 0 || this.TargetMonitor > monCount) {
            this.TargetMonitor := (monCount >= 2) ? 2 : 1
        }
    }

    static Save() {
        IniWrite(this.OneCmdProcess, this.ConfigFile, "Settings", "OneCmdProcess")
        IniWrite(this.EdgeProcess, this.ConfigFile, "Settings", "EdgeProcess")
        IniWrite(this.EdgeUrl, this.ConfigFile, "Settings", "EdgeUrl")
        IniWrite(this.TargetMonitor, this.ConfigFile, "Settings", "TargetMonitor")
        IniWrite(this.EdgeHotkey, this.ConfigFile, "Settings", "EdgeHotkey")
        IniWrite(this.StartupDelay, this.ConfigFile, "Settings", "StartupDelay")
        IniWrite(this.WindowReadyTimeout, this.ConfigFile, "Settings", "WindowReadyTimeout")
    }
}

; ==============================================================================
; 日志系统
; ==============================================================================

class Logger {
    static Init() {
        if FileExist(Config.LogFile)
            FileDelete(Config.LogFile)
        this.Write("=== 程序启动 ===")
    }

    static Write(msg) {
        if !Config.DebugMode
            return

        timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss") . "." . A_MSec
        logLine := "[" . timestamp . "] " . msg . "`r`n"

        try {
            FileAppend(logLine, Config.LogFile, "UTF-8")
        }
    }
}

; ==============================================================================
; 显示器工具
; ==============================================================================

class MonitorHelper {
    static GetRect(monitorIndex := 1) {
        if (monitorIndex > MonitorGetCount())
            monitorIndex := 1

        MonitorGet(monitorIndex, &L, &T, &R, &B)
        return { L: L, T: T, R: R, B: B, W: R - L, H: B - T }
    }
}

; ==============================================================================
; 窗口基类
; ==============================================================================

class WindowBase {
    ProcessName := ""
    TargetMonitor := 1
    Hwnd := 0
    Pid := 0
    IsInitialized := false  ; 标记是否已完成初始化

    __New(processName, monitorIndex) {
        this.ProcessName := processName
        this.TargetMonitor := monitorIndex
        Logger.Write("创建窗口实例: " . processName)
    }

    ; 启动进程（仅在首次初始化时调用）
    Launch(parameter := "") {
        if ProcessExist(this.ProcessName) {
            Logger.Write(this.ProcessName . " 进程已存在")
            if this.FindWindow() {
                this.IsInitialized := true
                return true
            }
        }

        try {
            runCmd := parameter ? '"' . this.ProcessName . '" "' . parameter . '"' : this.ProcessName
            Logger.Write("启动进程: " . runCmd)
            Run(runCmd)
            Sleep(3000)

            ; 等待窗口出现
            loop 20 {
                Sleep(500)
                if this.FindWindow() {
                    Logger.Write("进程启动成功")
                    this.IsInitialized := true
                    return true
                }
            }

            Logger.Write("警告: 进程启动超时")
            return false
        } catch as err {
            Logger.Write("错误: 无法启动 " . this.ProcessName . " - " . err.Message)
            MsgBox("无法启动进程: " . this.ProcessName . "`n错误: " . err.Message)
            return false
        }
    }

    ; 查找窗口句柄
    FindWindow() {
        if !ProcessExist(this.ProcessName) {
            if this.Hwnd != 0
                Logger.Write("进程丢失: " . this.ProcessName)
            this.Hwnd := 0
            this.Pid := 0
            return false
        }

        ; 如果现有句柄仍然有效，直接返回
        if this.Hwnd && WinExist("ahk_id " this.Hwnd)
            return true

        ; 查找新窗口
        hwndList := WinGetList("ahk_exe " . this.ProcessName)
        for hwnd in hwndList {
            if this.IsValidWindow(hwnd) {
                this.Hwnd := hwnd
                this.Pid := WinGetPID("ahk_id " hwnd)
                Logger.Write("找到窗口: " . this.ProcessName . " [Hwnd:" . hwnd . "]")
                return true
            }
        }

        return false
    }

    ; 验证窗口是否有效（可被子类覆盖）
    IsValidWindow(hwnd) {
        try {
            style := WinGetStyle("ahk_id " hwnd)
            if !(style & 0x10000000)  ; WS_VISIBLE
                return false

            ; 排除无标题窗口
            title := WinGetTitle("ahk_id " hwnd)
            return title != ""
        }
        return false
    }

    ; 移动窗口到目标显示器并最大化
    MoveToMonitor() {
        if !this.FindWindow()
            return

        Logger.Write("移动窗口到显示器 " . this.TargetMonitor)
        mon := MonitorHelper.GetRect(this.TargetMonitor)

        WinRestore("ahk_id " this.Hwnd)
        WinMove(mon.L, mon.T, mon.W, mon.H, "ahk_id " this.Hwnd)
        WinMaximize("ahk_id " this.Hwnd)
    }
}

; ==============================================================================
; 自动隐藏窗口（侧边栏）
; ==============================================================================

class AutoHideWindow extends WindowBase {
    IsHidden := false

    Init() {
        if !this.Launch()
            return false

        ; 等待窗口完全加载
        loop Config.WindowReadyTimeout * 5 {
            Sleep(200)
            if this.IsWindowReady() {
                Logger.Write("窗口就绪，初始化隐藏位置")
                this.Hide(true)
                return true
            }
        }

        Logger.Write("警告: 窗口就绪超时")
        return false
    }

    IsWindowReady() {
        if !this.FindWindow()
            return false

        try {
            title := WinGetTitle("ahk_id " this.Hwnd)
            style := WinGetStyle("ahk_id " this.Hwnd)
            return title != "" && style
        }
        return false
    }

    Update() {
        if !this.FindWindow()
            return

        MouseGetPos(&mx, &my, &hoverHwnd)
        hoverPid := 0
        try hoverPid := WinGetPID("ahk_id " hoverHwnd)

        shouldShow := this.IsMouseInTriggerZone(mx, my)
        isHovering := (hoverPid == this.Pid)

        if shouldShow && this.IsHidden {
            Logger.Write("触发显示")
            this.Show()
        } else if !isHovering && !shouldShow && !this.IsHidden {
            Logger.Write("触发隐藏")
            this.Hide()
        }
    }

    IsMouseInTriggerZone(x, y) {
        mon := MonitorHelper.GetRect(this.TargetMonitor)
        ; 左边缘 2px 宽，200px 高
        return (x >= mon.L && x < mon.L + 2) && (y >= mon.T && y < mon.T + 200)
    }

    Show() {
        if !this.IsHidden
            return

        WinShow("ahk_id " this.Hwnd)
        WinActivate("ahk_id " this.Hwnd)
        this.IsHidden := false
    }

    Hide(force := false) {
        if this.IsHidden && !force
            return

        mon := MonitorHelper.GetRect(this.TargetMonitor)
        targetW := mon.W / 2 + 20
        targetH := mon.H + 10

        try {
            if WinGetMinMax("ahk_id " this.Hwnd) == 1
                WinRestore("ahk_id " this.Hwnd)

            WinMove(mon.L - 10, mon.T, targetW, targetH, "ahk_id " this.Hwnd)
            WinHide("ahk_id " this.Hwnd)

            if WinActive("ahk_id " this.Hwnd)
                Send("!{Esc}")

            this.IsHidden := true
        }
    }

    RestoreOnExit() {
        Logger.Write("退出程序，恢复窗口")
        if this.Hwnd && WinExist("ahk_id " this.Hwnd)
            WinShow("ahk_id " this.Hwnd)
    }
}

; ==============================================================================
; 切换窗口（快捷键控制）
; ==============================================================================

class ToggleWindow extends WindowBase {
    Url := ""

    __New(processName, monitorIndex, url := "") {
        this.Url := url
        super.__New(processName, monitorIndex)
    }

    Init() {
        ; 首次启动时打开指定 URL
        this.Launch(this.Url)
        Sleep(3000)
        this.Toggle()
    }

    Toggle() {
        ; 如果未初始化，先初始化
        if !this.IsInitialized {
            this.Init()
            return
        }

        ; 查找窗口（不启动新进程）
        if !this.FindWindow() {
            Logger.Write("未找到窗口，可能已关闭")
            ; 重新初始化
            this.IsInitialized := false
            this.Init()
            return
        }

        ; 切换显示/隐藏
        if WinActive("ahk_id " this.Hwnd) {
            Logger.Write("隐藏窗口")
            WinHide("ahk_id " this.Hwnd)
            Send("!{Esc}")
        } else {
            Logger.Write("显示窗口")
            this.EnsureInMonitor()
            WinShow("ahk_id " this.Hwnd)
            WinActivate("ahk_id " this.Hwnd)
        }
    }

    ; 确保窗口在目标显示器内
    EnsureInMonitor() {
        WinGetPos(&x, &y, &w, &h, "ahk_id " this.Hwnd)
        centerX := x + (w / 2)
        centerY := y + (h / 2)
        mon := MonitorHelper.GetRect(this.TargetMonitor)

        isInMonitor := (centerX >= mon.L && centerX <= mon.R && centerY >= mon.T && centerY <= mon.B)

        if !isInMonitor {
            Logger.Write("窗口不在目标显示器，重新定位")
            this.MoveToMonitor()
        }
    }
}

; ==============================================================================
; 应用程序主类
; ==============================================================================

class App {
    static Commander := ""
    static Browser := ""
    static IsReady := false

    static Init() {
        ; 初始化环境
        SetTitleMatchMode(2)
        DetectHiddenWindows(true)
        SetWinDelay(10)
        SetKeyDelay(0)
        CoordMode("Mouse", "Screen")

        ; 加载配置
        Logger.Init()
        Config.Load()
        Logger.Write("目标显示器: " . Config.TargetMonitor . " / " . MonitorGetCount())

        ; 创建窗口实例
        this.Commander := AutoHideWindow(Config.OneCmdProcess, Config.TargetMonitor)
        this.Browser := ToggleWindow(Config.EdgeProcess, Config.TargetMonitor, Config.EdgeUrl)

        ; 延迟启动
        SetTimer(() => this.Start(), -Config.StartupDelay)

        ; 注册热键和退出处理
        Hotkey(Config.EdgeHotkey, (*) => this.Browser.Toggle())
        OnExit((reason, code) => this.OnExit())
    }

    static Start() {
        Logger.Write("开始初始化窗口...")

        ; 初始化窗口
        this.Commander.Init()
        this.Browser.Init()

        ; 启动主循环
        this.IsReady := true
        SetTimer(() => this.Tick(), Config.CheckInterval)
        Logger.Write("初始化完成")
    }

    static Tick() {
        if !this.IsReady
            return

        ; 更新自动隐藏窗口
        this.Commander.Update()

        ; 处理重命名窗口
        if WinActive("重命名 ahk_class #32770") {
            Send("y")
        }

        ; 调试信息
        if Config.DebugMode {
            debugInfo := "=== 窗口管理器 ===`n"
            debugInfo .= "Commander: " . (this.Commander.Hwnd ? "ID:" . this.Commander.Hwnd : "未找到")
            debugInfo .= " | Hidden: " . (this.Commander.IsHidden ? "是" : "否") . "`n"
            debugInfo .= "Browser: " . (this.Browser.Hwnd ? "ID:" . this.Browser.Hwnd : "未找到") . "`n"
            debugInfo .= "显示器: " . Config.TargetMonitor . "/" . MonitorGetCount()
            ToolTip(debugInfo, 10, 10)
        }
    }

    static OnExit() {
        this.Commander.RestoreOnExit()
        ToolTip()
    }
}

; ==============================================================================
; 程序入口
; ==============================================================================

App.Init()