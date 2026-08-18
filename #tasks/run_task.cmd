@echo off
setlocal EnableDelayedExpansion

@REM ============================================================
@REM  提权执行脚本（run_task.cmd）
@REM  由 #1)create.cmd 以管理员权限调用
@REM  职责：读取参数文件 -> 生成VBS(如需要) -> 执行schtasks -> 应用设置
@REM        详细输出写入 %temp%\taskmgr_result.txt，结尾返回退出码
@REM ============================================================

@REM 读取数据收集脚本写入的参数文件
call "%temp%\taskmgr_params.cmd" 2>nul
if not defined TR (
  echo [错误] 未找到有效参数文件，请通过 #1^)create.cmd 运行。> "%temp%\taskmgr_result.txt"
  exit /b 1
)

@REM 清空旧结果文件
> "%temp%\taskmgr_result.txt" echo === 任务创建结果 ===

@REM ------------------------------------------------------------
@REM 按窗口样式构建 /tr 的实际值（TR_ARG），与 #1)create.cmd 预览逻辑一致
@REM ------------------------------------------------------------
set "TR_ARG=!TR!"
if /i "!TASK_WINDOW_STYLE!"=="MINIMIZED" (
  set "TR_ARG=cmd /c start \^"\^" /min \^"!TR!\^""
) else if /i "!TASK_WINDOW_STYLE!"=="VBS" (
  set "TR_ARG=!TR_DIR!!BASE_NAME!.vbs"
)

@REM ------------------------------------------------------------
@REM VBS 方案：先在程序同目录生成同名 .vbs
@REM ------------------------------------------------------------
set "RC=0"
if /i "!TASK_WINDOW_STYLE!"=="VBS" (
  echo 正在生成 VBS 中转文件...>> "%temp%\taskmgr_result.txt"
  call "%~dp0gen_vbs.cmd" "!TR!" !TASK_VBS_STYLE! "!VBS_ALLOW_OVERWRITE!" >> "%temp%\taskmgr_result.txt" 2>&1
  if errorlevel 1 (
    echo [失败] VBS 生成失败！>> "%temp%\taskmgr_result.txt"
    set "RC=1"
    goto :finish
  )
)

@REM ------------------------------------------------------------
@REM 构建并执行 schtasks 创建命令
@REM ------------------------------------------------------------
set "CMD_SCHTASKS=schtasks /create /tn "\!TASK_FOLDER!\!TN!" /tr "!TR_ARG!" /sc !SC! /F /RL HIGHEST"
if not "!ST!"=="" set "CMD_SCHTASKS=!CMD_SCHTASKS! /st !ST!"
if not "!DELAY!"=="" set "CMD_SCHTASKS=!CMD_SCHTASKS! /delay !DELAY!"
if not "!RU!"=="" set "CMD_SCHTASKS=!CMD_SCHTASKS! /ru !RU!"
if not "!RP!"=="" set "CMD_SCHTASKS=!CMD_SCHTASKS! /rp !RP!"

echo.>> "%temp%\taskmgr_result.txt"
echo 正在创建计划任务...>> "%temp%\taskmgr_result.txt"
echo 命令: !CMD_SCHTASKS!>> "%temp%\taskmgr_result.txt"
!CMD_SCHTASKS! >> "%temp%\taskmgr_result.txt" 2>&1
if errorlevel 1 (
  echo [失败] 任务创建失败！>> "%temp%\taskmgr_result.txt"
  set "RC=1"
  goto :finish
)
echo [成功] 任务创建成功。>> "%temp%\taskmgr_result.txt"

@REM ------------------------------------------------------------
@REM 应用设置（电池限制 / 唤醒 / 其他），通过 PowerShell
@REM ------------------------------------------------------------
set "CMD_PS_1=try { $task = Get-ScheduledTask -TaskPath '\!TASK_FOLDER!\' -TaskName '!TN!' -ErrorAction Stop; "
if /i "!DISABLE_POWER_LIMITS!"=="true" (
  set "CMD_PS_1=!CMD_PS_1! $task.Settings.DisallowStartIfOnBatteries = $false; $task.Settings.StopIfGoingOnBatteries = $false; "
)
if /i "!WAKE_TO_RUN!"=="true" (
  set "CMD_PS_1=!CMD_PS_1! $task.Settings.WakeToRun = $true; "
)
set "CMD_PS_1=!CMD_PS_1! Set-ScheduledTask -InputObject $task; Write-Host '设置已应用' } catch { Write-Host '更新设置失败：' $_.Exception.Message }"
echo 正在应用设置...>> "%temp%\taskmgr_result.txt"
powershell -NoProfile -Command "!CMD_PS_1!" >> "%temp%\taskmgr_result.txt" 2>&1

:finish
echo.>> "%temp%\taskmgr_result.txt"
echo === 结束 ===>> "%temp%\taskmgr_result.txt"
exit /b %RC%
