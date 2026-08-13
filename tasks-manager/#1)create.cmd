@echo off
setlocal enabledelayedexpansion

@REM ------------------------------------------------------------
@REM 加载公共配置变量
@REM ------------------------------------------------------------
call "%~dp0config.cmd"

@REM ------------------------------------------------------------
@REM 转到管理员检测（避免在括号块内解析含 () 的路径）
@REM ------------------------------------------------------------
goto check_admin

:get_admin_and_run
@REM 已通过拖拽图标携带路径参数，但当前无管理员权限，需提权
if not exist "%~1" (
  echo 错误：文件不存在，请将有效的程序/脚本文件拖拽到此脚本图标上。
  pause
  exit /b
)
echo 正在请求管理员权限...
@REM 通过临时文件传递路径（避免空格/括号/中文被命令/环境变量拆散）
> "%temp%\taskmgr_path.txt" echo "%~1"
powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0'"
exit /b

:ask_path_and_admin
@REM 无参数、无权限：先输入路径再提权
echo ============================================================
echo  Windows 计划任务 创建助手
echo ============================================================
echo.
echo 请将程序/脚本文件拖拽到本窗口，或输入完整路径。
echo （拖拽时若路径含空格，请确认引号包裹完整）
echo.
:input_user_path
set "USER_PATH="
set /p "USER_PATH=请输入完整路径（不能为空）："
if "!USER_PATH!"=="" goto input_user_path
set "USER_PATH=!USER_PATH:"=!"
if not exist "!USER_PATH!" (
  echo 错误：文件不存在，请重新输入正确的路径。
  echo.
  goto input_user_path
)
echo 正在请求管理员权限并传递路径...
@REM 通过临时文件传递路径（避免空格/括号/中文被命令/环境变量拆散）
> "%temp%\taskmgr_path.txt" echo "!USER_PATH!"
powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0'"
exit /b

:check_admin
net session >nul 2>&1
if !errorlevel! equ 0 goto admin_branch
@REM 无权限
if "%~1"=="" goto ask_path_and_admin
goto get_admin_and_run

@REM ------------------------------------------------------------
@REM 管理员权限分支 - 获取路径（单次执行）
@REM ------------------------------------------------------------
:admin_branch
@REM 优先从临时文件读取路径（提权后，完整保留空格/括号/中文）
if exist "%temp%\taskmgr_path.txt" (
  set /p "TR="<"%temp%\taskmgr_path.txt"
  del "%temp%\taskmgr_path.txt" >nul 2>&1
  set "TR=!TR:"=!"
  goto process_path
)
@REM 其次使用命令行参数（直接以管理员身份运行并拖拽到脚本图标）
if not "%~1"=="" (
  set "TR=%~1"
  goto process_path
)

echo ============================================================
echo  Windows 计划任务 创建助手
echo ============================================================
echo.
echo 请将程序/脚本文件拖拽到本窗口，或输入完整路径。
echo.
:input_path
set "USER_PATH="
set /p "USER_PATH=请输入完整路径（不能为空）："
if "!USER_PATH!"=="" (
  echo.
  echo 已退出。
  pause
  exit /b
)
set "USER_PATH=!USER_PATH:"=!"
if not exist "!USER_PATH!" (
  echo 错误：文件不存在，请重新输入正确的路径。
  echo.
  goto input_path
)
set "TR=!USER_PATH!"

:process_path
for %%I in ("!TR!") do set "TN=%%~nI"
echo ============================================================
echo  Windows 计划任务 创建助手
echo ============================================================
echo.
echo 检测到程序路径：!TR!
echo 任务名称：!TN!
echo 任务组：!TASK_FOLDER!
echo.

@REM ------------------------------------------------------------
@REM 确保任务文件夹存在（schtasks /create 会自动创建，预创建无妨）
@REM ------------------------------------------------------------
@REM schtasks /query /tn "\!TASK_FOLDER!\" >nul 2>&1
@REM if !errorlevel! neq 0 (
@REM  echo 正在创建任务文件夹 !TASK_FOLDER!...
@REM  powershell -Command "New-Item -Path 'C:\Windows\System32\Tasks\!TASK_FOLDER!' -ItemType Directory -Force" >nul 2>&1
@REM  echo 文件夹创建完成。
@REM  echo.
@REM )

@REM ------------------------------------------------------------
@REM 计划类型
@REM ------------------------------------------------------------
:input_sc
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

@REM ------------------------------------------------------------
@REM 开始时间
@REM ------------------------------------------------------------
if !NEED_TIME! EQU 1 (
  :input_st
  set "ST="
  set /p "ST=请输入开始时间（如 8:00 或 08:00，直接回车=06:00）："
  if "!ST!"=="" set "ST=06:00"
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
  if !HOUR! LSS 10 set "HOUR=0!HOUR!"
  if !MINUTE! LSS 10 set "MINUTE=0!MINUTE!"
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
  set "DELAY_SEC="
  :input_delay
  set /p "DELAY_SEC=请输入延迟秒数（输入数字，如 30 表示 30 秒，直接回车=0）："
  if "!DELAY_SEC!"=="" set "DELAY_SEC=0"
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
echo.
echo 请选择运行任务的用户账户（/ru）：
echo  --------------------------------------
echo  1. 当前用户（最高权限，推荐） [默认]
echo  2. SYSTEM（系统账户，最高权限，无需密码）
echo  3. 其他用户
echo  --------------------------------------
echo.
:input_ru
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
@REM ------------------------------------------------------------
:input_confirm
choice /c yn /n /m "确认执行？（Y 确认 / N 取消）："
if !errorlevel! EQU 1 (
  echo.
  echo 正在创建任务...
  !CMD! >nul 2>&1
  set "ERRCODE=!errorlevel!"
  echo.
  if !ERRCODE! equ 0 (
    echo 任务创建成功，正在应用设置...
    echo.
    @REM 使用 !TN! 引用任务名称
    set "POWERSHELL_CMD=try { $task = Get-ScheduledTask -TaskPath '\!TASK_FOLDER!\' -TaskName '!TN!' -ErrorAction Stop; "
    if /i "!DISABLE_POWER_LIMITS!"=="true" (
      set "POWERSHELL_CMD=!POWERSHELL_CMD! $task.Settings.DisallowStartIfOnBatteries = $false; $task.Settings.StopIfGoingOnBatteries = $false; "
    )
    if /i "!WAKE_TO_RUN!"=="true" (
      set "POWERSHELL_CMD=!POWERSHELL_CMD! $task.Settings.WakeToRun = $true; "
    )
    set "POWERSHELL_CMD=!POWERSHELL_CMD! Set-ScheduledTask -InputObject $task; Write-Host '设置已应用' } catch { Write-Host '更新设置失败：' $_.Exception.Message; exit 1 }"
    powershell -Command "!POWERSHELL_CMD!"
    if !errorlevel! equ 0 (
      echo 设置已成功应用。
      ) else (
      echo 注意：设置修改可能未成功，请手动检查任务属性。
    )
    ) else (
    echo 任务创建失败，请检查错误信息。
  )
  echo.
  echo 任务创建流程结束。
  pause
  exit /b 0
)
if !errorlevel! EQU 2 (
  @REM 手动清空所有相关变量，实现“重置”效果
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
)
