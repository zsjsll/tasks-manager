@echo off
setlocal enabledelayedexpansion

@REM ------------------------------------------------------------
@REM 加载公共配置变量
@REM ------------------------------------------------------------
call "%~dp0config.cmd"

@REM ------------------------------------------------------------
@REM 自动提权
@REM ------------------------------------------------------------
net session >nul 2>&1
if !errorlevel! neq 0 (
  echo 当前未以管理员身份运行，正在请求提权...
  timeout /t 1 /nobreak >nul
  powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

@REM ------------------------------------------------------------
@REM 主程序
@REM ------------------------------------------------------------
:main
cls
echo ============================================================
echo  /!TASK_FOLDER! 目录任务管理
echo ============================================================

set "MAPFILE=%temp%\taskmap.txt"
> "%MAPFILE%" echo.

powershell -command "$i=1; Get-ScheduledTask -TaskPath '\!TASK_FOLDER!\' | ForEach-Object { $name=$_.TaskName; $state=$_.State; Write-Host ('{0}. {1} ({2})' -f $i, $name, $state); Add-Content -Path '%MAPFILE%' -Value ('{0}|{1}' -f $i, $name); $i++ }"

for /f %%A in ("%MAPFILE%") do set "MAPSIZE=%%~zA"
if not defined MAPSIZE set "MAPSIZE=0"
if !MAPSIZE! EQU 0 (
  echo 没有找到任何任务或无法读取目录。
  echo 按任意键退出...
  pause >nul
  goto :eof
)

@REM ------------------------------------------------------------
@REM 选择任务阶段：仅显示一次提示，循环内只读输入
@REM ------------------------------------------------------------
echo.
echo 输入编号进行操作，或输入 0 退出
echo.
:choose_task_loop
set /p "CHOICE=请输入编号： "

if "!CHOICE!"=="0" goto :eof
if "!CHOICE!"=="" goto choose_task_loop

@REM 根据编号查找任务名
set "TASKNAME="
for /f "tokens=1,2 delims=|" %%a in ('type "%MAPFILE%"') do (
  if "%%a"=="!CHOICE!" set "TASKNAME=%%b"
)
if not defined TASKNAME goto choose_task_loop

@REM ------------------------------------------------------------
@REM 操作菜单阶段：菜单显示一次，循环内只读输入
@REM ------------------------------------------------------------
echo.
echo 当前任务： !TASKNAME!
echo.
echo 请选择：
echo.
echo  --------------------------------------
echo  [1] 暂停（禁用）
echo  [2] 启用
echo  --------------------------------------
echo  [3] 停止（终止运行中的任务）
echo  [4] 运行（立即触发）
echo  --------------------------------------
echo  [5] 删除
echo  --------------------------------------
echo  [6] 返回上级菜单
echo  --------------------------------------
echo.
:action_loop
set /p "ACT=请输入编号： "

if "!ACT!"=="" goto action_loop
if "!ACT!"=="6" (
  set "CHOICE="
  goto main
)

@REM 判断是否为有效操作(1-5)，若不是则重新输入
if not "!ACT!"=="1" if not "!ACT!"=="2" if not "!ACT!"=="3" if not "!ACT!"=="4" if not "!ACT!"=="5" goto action_loop

@REM 有效操作，先空一行再继续
echo.

if "!ACT!"=="1" (
  echo 正在执行： schtasks /change /tn "\!TASK_FOLDER!\!TASKNAME!" /disable
  echo.
  schtasks /change /tn "\!TASK_FOLDER!\!TASKNAME!" /disable
  if !errorlevel! neq 0 (
    echo.
    echo [失败] 操作返回错误代码 !errorlevel!
  )
  echo.
  echo 按任意键返回主菜单...
  pause >nul
  goto main
)

if "!ACT!"=="2" (
  echo 正在执行： schtasks /change /tn "\!TASK_FOLDER!\!TASKNAME!" /enable
  echo.
  schtasks /change /tn "\!TASK_FOLDER!\!TASKNAME!" /enable
  if !errorlevel! neq 0 (
    echo.
    echo [失败] 操作返回错误代码 !errorlevel!
  )
  echo.
  echo 按任意键返回主菜单...
  pause >nul
  goto main
)

if "!ACT!"=="3" (
  echo 正在执行： schtasks /end /tn "\!TASK_FOLDER!\!TASKNAME!"
  echo.
  schtasks /end /tn "\!TASK_FOLDER!\!TASKNAME!"
  if !errorlevel! neq 0 (
    echo.
    echo [失败] 操作返回错误代码 !errorlevel!（可能任务未运行）
  )
  echo.
  echo 按任意键返回主菜单...
  pause >nul
  goto main
)

if "!ACT!"=="4" (
  echo 正在执行： schtasks /run /tn "\!TASK_FOLDER!\!TASKNAME!"
  echo.
  schtasks /run /tn "\!TASK_FOLDER!\!TASKNAME!"
  if !errorlevel! neq 0 (
    echo.
    echo [失败] 操作返回错误代码 !errorlevel!（可能任务未就绪）
  )
  echo.
  echo 按任意键返回主菜单...
  pause >nul
  goto main
)

if "!ACT!"=="5" (
  echo 警告：即将删除任务 "!TASKNAME!"
  set /p "CONFIRM=确认删除？（输入 y 确认）： "
  if /i "!CONFIRM!"=="y" (
    echo 正在执行： schtasks /delete /tn "\!TASK_FOLDER!\!TASKNAME!" /f
    echo.
    schtasks /delete /tn "\!TASK_FOLDER!\!TASKNAME!" /f
    if !errorlevel! neq 0 (
      echo.
      echo [失败] 操作返回错误代码 !errorlevel!
    )
  ) else (
    echo 取消删除。
  )
  echo.
  echo 按任意键返回主菜单...
  pause >nul
  goto main
)
