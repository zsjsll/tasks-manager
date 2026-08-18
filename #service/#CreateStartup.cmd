@echo off
setlocal EnableDelayedExpansion

REM ===== 引入公共配置 =====
call "%~dp0cfg.cmd"

REM ===== 生成 VBS 文件 =====
(
echo Option Explicit
echo.
echo Dim shellApp, exePath, exeArgs, workingDir, windowStyle
echo Set shellApp = CreateObject("Shell.Application"^)
echo.
echo exePath  = "!EXE_PATH!"
echo exeArgs  = "!EXE_ARGS!"
echo workingDir  = "..\"
echo windowStyle = !WINDOW_STYLE!
echo.
echo shellApp.ShellExecute exePath, exeArgs, workingDir, "runas", windowStyle
) > "!ABS_VBS_PATH!"

REM ===== 临时 VBS 创建快捷方式 =====
set "TempVbs=!temp!\CreateShortcut_!BASE_NAME!.vbs"

(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo Set Shortcut = WshShell.CreateShortcut("!ShortcutPath!"^)
echo Shortcut.TargetPath = "!ABS_VBS_PATH!"
echo Shortcut.WorkingDirectory = "!ABS_VBS_DIR!"
echo Shortcut.IconLocation = "!ABS_EXE_PATH!,0"
echo Shortcut.WindowStyle = 7
echo Shortcut.Description = "!BASE_NAME!"
echo Shortcut.Save
) > "!TempVbs!"

REM 运行 VBScript，创建快捷方式
cscript //nologo "!TempVbs!"
REM 清理临时脚本
del /F /Q "!TempVbs!"

echo.
echo 快捷方式已创建：
echo !ShortcutPath!
echo.
echo VBS 文件位置：
echo !ABS_VBS_PATH!
echo.

pause
endlocal
