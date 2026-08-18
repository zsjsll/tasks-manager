@echo off
REM ===== 公共配置（只改这里）=====

set "EXE_PATH="
@REM 0 隐藏窗口并激活另一个窗口
@REM 1 激活并显示窗口，还原为原始大小位置
@REM 2 激活窗口并将其显示为最小化
@REM 3 激活窗口并将其显示为最大化
@REM 4 按最近大小位置显示，不激活
@REM 5 以当前状态激活并显示窗口
@REM 6 最小化指定窗口并激活下一个顶层窗口
@REM 7 最小化显示，保持当前活动窗口
@REM 8 以当前状态显示，不激活
@REM 9 激活并显示窗口，还原最小化/最大化
@REM 10 根据程序启动信息设定的状态显示
set "WINDOW_STYLE=7"
set "EXE_ARGS="

REM ===== 判断执行文件是否存在，并推导路径 =====
pushd "%~dp0" 2>nul

for %%i in ("%EXE_PATH%") do (
  rem 判断是否存在
  if not exist "%%~fi" (
    echo ERROR: 无法找到执行文件：%%~fi
    echo 请重新配置 "%~nx0" 中的 EXE_PATH
    pause
    popd 2>nul
    endlocal
    exit 1
  )

  rem 推导信息
  set "ABS_EXE_PATH=%%~fi"
  set "ABS_EXE_DIR=%%~dpi"
  set "BASE_NAME=%%~ni"
  set "EXE_NAME=%%~ni.exe"
)

popd 2>nul

REM ===== VBS 变量 =====
set "VBS_NAME=!BASE_NAME!.vbs"
set "ABS_VBS_DIR=%~dp0"
set "ABS_VBS_PATH=!ABS_VBS_DIR!!VBS_NAME!"

REM ===== 启动项快捷方式变量 =====
set "ShortcutName=!BASE_NAME!.lnk"
set "StartupFolder=!APPDATA!\Microsoft\Windows\Start Menu\Programs\Startup\"
set "ShortcutPath=!StartupFolder!!ShortcutName!"
