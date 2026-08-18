@echo off
setlocal enabledelayedexpansion

@REM ------------------------------------------------------------
@REM 加载公共配置变量
@REM ------------------------------------------------------------
call "%~dp0config.cmd"

@REM ============================================================
@REM 主界面模式（非提权运行，可拖拽图标、可循环）
@REM 说明：由于 UIPI 安全机制，已提权的窗口无法接收拖拽。
@REM       因此主界面保持非提权，仅在真正执行 schtasks 时
@REM       生成独立临时脚本并以管理员权限运行，从而让拖拽始终可用。
@REM ============================================================
:main_loop
@REM 若拖拽文件到脚本图标（带有路径参数），直接使用该路径（优先级最高）
if not "%~1"=="" goto use_arg_path
@REM 若配置文件设置了 TASK_NAME，则直接作为任务名使用（与路径独立判断）
if defined TASK_NAME (
  set "TN=!TASK_NAME!"
  set "TASK_NAME="
)
@REM 若配置文件设置了 TARGET_PATH，则直接用它作为路径并跳过输入
if defined TARGET_PATH (
  pushd "%~dp0"
  set "TR=!TARGET_PATH!"
  for %%I in ("!TR!") do set "TR=%%~fI"
  popd
  set "TARGET_PATH="
  goto config_got_path
)

cls
echo ============================================================
echo  Windows 计划任务 创建助手
echo ============================================================
echo.
echo 请将程序/脚本文件拖拽到本窗口，或输入完整路径。
echo 直接回车（不输入）可退出。
echo.
:input_path
set "TR="
set /p "TR=请输入完整路径（不能为空）："
if "!TR!"=="" (
  echo 输入为空，请重新输入路径。
  echo.
  goto input_path
)
set "TR=!TR:"=!"
if not exist "!TR!" (
  echo 错误：文件不存在，请重新输入正确的路径。
  echo.
  goto input_path
)
goto got_path

@REM 拖拽到脚本图标（带路径参数）时使用参数
:use_arg_path
set "TR=%~1"
shift
set "TR=!TR:"=!"
if not exist "!TR!" (
  echo 错误：文件不存在，请将有效的程序/脚本文件拖拽到此脚本。
  pause
  exit /b
)

@REM 配置文件路径：校验转换后的路径存在后进入正常流程
:config_got_path
set "TR=!TR:"=!"
if not exist "!TR!" (
  echo 错误：配置中 TARGET_PATH 指定的文件不存在，请检查 config.cmd。
  echo.
  pause
  exit /b
)
goto got_path

:got_path
if "!TN!"=="" for %%I in ("!TR!") do set "TN=%%~nI"
echo ============================================================
echo  Windows 计划任务 创建助手
echo ============================================================
echo.
echo 检测到程序路径：!TR!
echo 任务名称：!TN!
echo 任务组：!TASK_FOLDER!
echo.

@REM ------------------------------------------------------------
@REM 计划类型
@REM ------------------------------------------------------------
:input_sc
@REM 若配置了 TASK_SCHEDULE_TYPE，则直接使用并跳过交互
if defined TASK_SCHEDULE_TYPE (
  set "SC=!TASK_SCHEDULE_TYPE!"
  set "SC_VALID=0"
  for %%a in (ONLOGON ONSTART ONIDLE DAILY WEEKLY MONTHLY ONCE) do (
    if /i "!SC!"=="%%a" (
      set "SC=%%a"
      set "SC_VALID=1"
    )
  )
  if "!SC_VALID!"=="1" (
    echo [自动] 计划类型：!SC!（来自配置 TASK_SCHEDULE_TYPE）
    echo.
    goto :sc_confirmed
  )
  echo 错误：config.cmd 中 TASK_SCHEDULE_TYPE 无效（!SC!）。
  echo 支持的值：ONLOGON/ONSTART/ONIDLE/DAILY/WEEKLY/MONTHLY/ONCE
  echo 将进入交互式选择。
  echo.
  set "TASK_SCHEDULE_TYPE="
  set "SC="
)
echo 请选择计划类型（/sc）：
echo  --------------------------------------
echo  1. 用户登录时 (ONLOGON)  [默认]
echo  2. 系统启动时 (ONSTART)
echo  3. 系统空闲时 (ONIDLE)
echo  --------------------------------------
echo  4. 每天 (DAILY)
echo  5. 每周 (WEEKLY)
echo  6. 每月 (MONTHLY)
echo  7. 一次 (ONCE)
echo  --------------------------------------
set "SC_CHOICE="
echo.
set /p "SC_CHOICE=请输入选项编号 [1-7]："
if "!SC_CHOICE!"=="" set "SC_CHOICE=1"
if "!SC_CHOICE!"=="1" set "SC=ONLOGON"
if "!SC_CHOICE!"=="2" set "SC=ONSTART"
if "!SC_CHOICE!"=="3" set "SC=ONIDLE"
if "!SC_CHOICE!"=="4" set "SC=DAILY"
if "!SC_CHOICE!"=="5" set "SC=WEEKLY"
if "!SC_CHOICE!"=="6" set "SC=MONTHLY"
if "!SC_CHOICE!"=="7" set "SC=ONCE"
if not defined SC (
  echo 无效选项，请重新输入。
  echo.
  goto input_sc
)

:sc_confirmed

@REM ------------------------------------------------------------
@REM 判断需要时间还是延迟
@REM ------------------------------------------------------------
set "NEED_TIME=0"
set "NEED_DELAY=0"
if "!SC!"=="DAILY" set "NEED_TIME=1"
if "!SC!"=="WEEKLY" set "NEED_TIME=1"
if "!SC!"=="MONTHLY" set "NEED_TIME=1"
if "!SC!"=="ONCE" set "NEED_TIME=1"
if "!SC!"=="ONSTART" set "NEED_DELAY=1"
if "!SC!"=="ONLOGON" set "NEED_DELAY=1"
if "!SC!"=="ONIDLE" set "NEED_DELAY=1"

@REM 若配置了不适用于当前计划类型的开始时间/延迟，给出提示并忽略
if defined TASK_START_TIME (
  if !NEED_TIME! EQU 0 (
    echo [配置] TASK_START_TIME 不适用于计划类型 !SC!（不需要开始时间），已忽略。
    set "TASK_START_TIME="
  )
)
if defined TASK_DELAY_SECONDS (
  if !NEED_DELAY! EQU 0 (
    echo [配置] TASK_DELAY_SECONDS 不适用于计划类型 !SC!（不支持延迟），已忽略。
    set "TASK_DELAY_SECONDS="
  )
)

@REM ------------------------------------------------------------
@REM 开始时间
@REM ------------------------------------------------------------
if !NEED_TIME! EQU 1 (
  @REM 若配置了 TASK_START_TIME，则直接使用并跳过交互
  if defined TASK_START_TIME (
    set "ST=!TASK_START_TIME!"
    set "TASK_START_TIME="
    goto :st_check
  )
  :input_st
  set "ST="
  set /p "ST=请输入开始时间（如 8:00 或 08:00，直接回车=06:00）："
  if "!ST!"=="" set "ST=06:00"
  :st_check
  for /f "tokens=1,2 delims=:" %%a in ("!ST!") do (
    set "HOUR=%%a"
    set "MINUTE=%%b"
  )
  if "!MINUTE!"=="" set "MINUTE=00"
  @REM 验证时间合法性（先校验是否为数字）
  echo !HOUR!|findstr /r "^[0-9][0-9]*$" >nul
  if !errorlevel! neq 0 (
    echo 小时必须是数字，请重新输入。
    echo.
    goto input_st
  )
  echo !MINUTE!|findstr /r "^[0-9][0-9]*$" >nul
  if !errorlevel! neq 0 (
    echo 分钟必须是数字，请重新输入。
    echo.
    goto input_st
  )
  set /a HOUR=!HOUR! 2>nul
  set /a MINUTE=!MINUTE! 2>nul
  if !HOUR! GEQ 24 (
    echo 小时不能大于23，请重新输入。
    goto input_st
  )
  if !MINUTE! GEQ 60 (
    echo 分钟不能大于59，请重新输入。
    goto input_st
  )
  set "HOURP=0!HOUR!"
  set "HOUR=!HOURP:~-2!"
  set "MINUTEP=0!MINUTE!"
  set "MINUTE=!MINUTEP:~-2!"
  set "ST=!HOUR!:!MINUTE!"
  echo [自动] 标准化时间：!ST!
  set "DELAY="
  goto :skip_delay
)

@REM ------------------------------------------------------------
@REM 延迟执行
@REM ------------------------------------------------------------
if !NEED_DELAY! EQU 1 (
  echo.
  echo 计划类型为 !SC!，支持延迟执行。
  echo.
  @REM 若配置了 TASK_DELAY_SECONDS，则直接使用并跳过交互
  if defined TASK_DELAY_SECONDS (
    set "DELAY_SEC=!TASK_DELAY_SECONDS!"
    set "TASK_DELAY_SECONDS="
    goto :delay_check
  )
  set "DELAY_SEC="
  :input_delay
  set /p "DELAY_SEC=请输入延迟秒数（输入数字，如 30 表示 30 秒，直接回车=0）："
  if "!DELAY_SEC!"=="" set "DELAY_SEC=0"
  :delay_check
  echo !DELAY_SEC!|findstr /r "^[0-9][0-9]*$" >nul
  if !errorlevel! neq 0 (
    echo 无效输入，请输入数字。
    echo.
    goto input_delay
  )
  @REM 限制最大秒数（24小时）
  if !DELAY_SEC! GEQ 86400 (
    echo 延迟秒数不能超过 86400（24小时），请重新输入。
    echo.
    goto input_delay
  )

  set /a HOURS=!DELAY_SEC! / 3600
  set /a REMAIN=!DELAY_SEC! %% 3600
  set /a MINUTES=!REMAIN! / 60
  set /a SECONDS=!REMAIN! %% 60
  if !HOURS! GTR 0 (
    set "DISPLAY=!HOURS!时!MINUTES!分!SECONDS!秒"
    ) else if !MINUTES! GTR 0 (
    set "DISPLAY=!MINUTES!分!SECONDS!秒"
    ) else (
    set "DISPLAY=!SECONDS!秒"
  )

  @REM 生成符合 schtasks /delay 的格式：mmmm:ss（分钟四位:秒两位）
  set /a TOTAL_MINUTES=!DELAY_SEC! / 60
  set /a REMAIN_SEC=!DELAY_SEC! %% 60
  set "MINUTES_PADDED=0000!TOTAL_MINUTES!"
  set "MINUTES_PADDED=!MINUTES_PADDED:~-4!"
  set "SECONDS_PADDED=00!REMAIN_SEC!"
  set "SECONDS_PADDED=!SECONDS_PADDED:~-2!"
  set "DELAY=!MINUTES_PADDED!:!SECONDS_PADDED!"
  if !DELAY_SEC! EQU 0 set "DELAY="

  echo [自动] 延迟时间：!DELAY! ^（即 !DISPLAY!^）
  echo.
  set "ST="
)
:skip_delay

@REM ------------------------------------------------------------
@REM 运行账户
@REM ------------------------------------------------------------
:input_ru
@REM 若配置了 TASK_RUN_USER，则直接使用并跳过交互
if defined TASK_RUN_USER (
  if /i "!TASK_RUN_USER!"=="CURRENT" (
    set "RU="
    set "RP="
    echo [自动] 运行账户：当前用户（来自配置 TASK_RUN_USER）
  ) else if /i "!TASK_RUN_USER!"=="SYSTEM" (
    set "RU=SYSTEM"
    set "RP="
    echo [自动] 运行账户：SYSTEM（来自配置 TASK_RUN_USER）
  ) else (
    set "RU=!TASK_RUN_USER!"
    set "RP=!TASK_RUN_PASSWORD!"
    echo [自动] 运行账户：!RU!（来自配置 TASK_RUN_USER）
  )
  set "TASK_RUN_USER="
  echo.
  goto :ru_confirmed
)
echo.
echo 请选择运行任务的用户账户（/ru）：
echo  --------------------------------------
echo  1. 当前用户（最高权限，推荐） [默认]
echo  2. SYSTEM（系统账户，最高权限，无需密码）
echo  3. 其他用户
echo  --------------------------------------
echo.
set "RU_CHOICE="
set /p "RU_CHOICE=请输入选项编号 [1-3]（直接回车=1）："
if "!RU_CHOICE!"=="" set "RU_CHOICE=1"
if "!RU_CHOICE!"=="1" (
  set "RU="
  set "RP="
  ) else if "!RU_CHOICE!"=="2" (
  set "RU=SYSTEM"
  set "RP="
  ) else if "!RU_CHOICE!"=="3" (
  :input_ru_custom
  set "RU="
  set /p "RU=请输入用户名（格式：域名\用户名）："
  if "!RU!"=="" (
    echo 用户名不能为空。
    echo.
    goto input_ru_custom
  )
  set "RP="
  set /p "RP=请输入该用户的密码："
  ) else (
  echo 无效选项，请重新输入。
  echo.
  goto input_ru
)

:ru_confirmed

@REM ------------------------------------------------------------
@REM 构建并执行
@REM ------------------------------------------------------------
echo.
echo ============================================================
echo.
echo 即将执行以下命令创建计划任务：
echo.
set "CMD=schtasks /create /tn "\!TASK_FOLDER!\!TN!" /tr "!TR!" /sc !SC! /F /RL HIGHEST"
if not "!ST!"=="" set "CMD=!CMD! /st !ST!"
if not "!DELAY!"=="" set "CMD=!CMD! /delay !DELAY!"
if not "!RU!"=="" set "CMD=!CMD! /ru !RU!"
if not "!RP!"=="" set "CMD=!CMD! /rp !RP!"

echo  !CMD!
echo.
echo.
echo [配置文件] 将要应用的设置：
echo.
set "SETTINGS_COUNT=0"
if /i "!DISABLE_POWER_LIMITS!"=="true" (
  echo  - 禁用电池限制（允许充电时运行）
  set /a SETTINGS_COUNT+=1
)
if /i "!WAKE_TO_RUN!"=="true" (
  echo  - 启用唤醒运行
  set /a SETTINGS_COUNT+=1
)
if !SETTINGS_COUNT! EQU 0 (
  echo  - 未应用额外设置
)
echo.
echo ============================================================
echo.

@REM ------------------------------------------------------------
@REM 确认执行（按 N 返回计划类型选择）
@REM 确认后生成一个独立临时执行脚本（位于 %temp%，路径简单），
@REM 用管理员权限运行它，避免主脚本路径含 () 导致的解析问题。
@REM 完成后返回主界面（可继续拖拽）。
@REM ------------------------------------------------------------
:input_confirm
choice /c yn /n /m "确认执行？（Y 确认 / N 取消）："
if !errorlevel! EQU 2 goto input_confirm_reset
goto do_exec

@REM ------------------------------------------------------------
@REM 按 N 取消 / 重置：回到计划类型选择
@REM ------------------------------------------------------------
:input_confirm_reset
set "SC_CHOICE="
set "SC="
set "ST="
set "DELAY="
set "RU_CHOICE="
set "RU="
set "RP="
set "NEED_TIME=0"
set "NEED_DELAY=0"
cls
echo ============================================================
echo  Windows 计划任务 创建助手
echo ============================================================
echo.
echo 检测到程序路径：!TR!
echo 任务名称：!TN!
echo 任务组：!TASK_FOLDER!
echo.
timeout /t 1 /nobreak >nul
goto :input_sc

@REM ------------------------------------------------------------
@REM 生成临时执行脚本（移出括号块，避免含 () 的路径/名字提前闭合括号）
@REM ------------------------------------------------------------
:do_exec
@REM 构建 schtasks 命令
set "CMD_SCHTASKS=schtasks /create /tn "\!TASK_FOLDER!\!TN!" /tr "!TR!" /sc !SC! /F /RL HIGHEST"
if not "!ST!"=="" set "CMD_SCHTASKS=!CMD_SCHTASKS! /st !ST!"
if not "!DELAY!"=="" set "CMD_SCHTASKS=!CMD_SCHTASKS! /delay !DELAY!"
if not "!RU!"=="" set "CMD_SCHTASKS=!CMD_SCHTASKS! /ru !RU!"
if not "!RP!"=="" set "CMD_SCHTASKS=!CMD_SCHTASKS! /rp !RP!"

@REM 构建 PowerShell 设置命令
set "CMD_PS_1=try { $task = Get-ScheduledTask -TaskPath '\!TASK_FOLDER!\' -TaskName '!TN!' -ErrorAction Stop; "
if /i "!DISABLE_POWER_LIMITS!"=="true" (
  set "CMD_PS_1=!CMD_PS_1! $task.Settings.DisallowStartIfOnBatteries = $false; $task.Settings.StopIfGoingOnBatteries = $false; "
)
if /i "!WAKE_TO_RUN!"=="true" (
  set "CMD_PS_1=!CMD_PS_1! $task.Settings.WakeToRun = $true; "
)
set "CMD_PS_1=!CMD_PS_1! Set-ScheduledTask -InputObject $task; Write-Host '设置已应用' } catch { Write-Host '更新设置失败：' $_.Exception.Message }"

@REM 生成临时执行脚本（逐行写入，路径简单，避开 -> 问题）
@REM 不切换代码页，保持与主脚本一致的编码，避免中文乱码
>  "%temp%\taskmgr_exec.cmd" echo @echo off
>> "%temp%\taskmgr_exec.cmd" echo @chcp 936 ^>nul
>> "%temp%\taskmgr_exec.cmd" echo echo.
>> "%temp%\taskmgr_exec.cmd" echo echo 正在创建计划任务...
>> "%temp%\taskmgr_exec.cmd" echo !CMD_SCHTASKS!
>> "%temp%\taskmgr_exec.cmd" echo if errorlevel 1 ^(echo 任务创建失败 ^& pause ^& exit /b 1^)
>> "%temp%\taskmgr_exec.cmd" echo echo 任务创建成功，正在应用设置...
>> "%temp%\taskmgr_exec.cmd" echo powershell -Command "!CMD_PS_1!"
>> "%temp%\taskmgr_exec.cmd" echo echo.
>> "%temp%\taskmgr_exec.cmd" echo echo 任务创建完成，按任意键关闭本窗口...
>> "%temp%\taskmgr_exec.cmd" echo pause ^>nul

echo.
echo 正在请求管理员权限并创建任务...
echo （请在弹出窗口中确认提权）
echo.
powershell -Command "Start-Process -Verb RunAs -FilePath 'cmd.exe' -ArgumentList '/c','%temp%\taskmgr_exec.cmd' -Wait"
echo.
echo 任务创建流程结束。
echo.
echo 按任意键返回，可再次拖拽图标继续创建任务（或直接关闭窗口退出）...
pause >nul
goto main_loop
