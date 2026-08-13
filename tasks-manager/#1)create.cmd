@echo off
setlocal enabledelayedexpansion

@REM ------------------------------------------------------------
@REM 加载公共配置变量
@REM ------------------------------------------------------------
call "%~dp0config.cmd"

@REM ------------------------------------------------------------
@REM 检查管理员权限
@REM ------------------------------------------------------------
net session >nul 2>&1
if !errorlevel! neq 0 (
  if not "%~1"=="" (
    if not exist "%~1" (
      echo 错误：文件不存在，请将有效的程序/脚本文件拖拽到此脚本图标上。
      pause
      exit /b
    )
    echo 正在请求管理员权限...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0' -ArgumentList \"%~1\""
  ) else (
    echo ============================================================
    echo  Windows 计划任务 创建助手
    echo ============================================================
    echo.
    :input_user_path
    set "user_path="
    set /p "user_path=请输入完整路径（不能为空）： "
    if "!user_path!"=="" goto input_user_path
    if not exist "!user_path!" (
      echo 错误：文件不存在，请重新输入正确的路径。
      echo.
      goto input_user_path
    )
    echo 正在请求管理员权限并传递路径...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0' -ArgumentList \"!user_path!\""
  )
  exit /b
)

@REM ------------------------------------------------------------
@REM 管理员权限分支
@REM ------------------------------------------------------------
@REM 检查是否传递了路径参数（防止双击以管理员身份运行但无参数）
if "%~1"=="" (
  echo 错误：未传递程序路径，请通过拖拽或手动输入启动。
  pause
  exit /b
)

set "tr=%~1"
for %%I in ("!tr!") do set "tn=%%~nI"
echo ============================================================
echo  Windows 计划任务 创建助手
echo ============================================================
echo.
echo [自动] 检测到程序路径： !tr!
echo [自动] 任务名称： !tn!
echo [自动] 任务组： !TASK_FOLDER!
echo.

@REM ------------------------------------------------------------
@REM 确保任务文件夹存在（schtasks /create 会自动创建，预创建无妨）
@REM ------------------------------------------------------------
@REM schtasks /query /tn "\!TASK_FOLDER!\" >nul 2>&1
@REM if !errorlevel! neq 0 (
@REM   echo 正在创建任务文件夹 !TASK_FOLDER!...
@REM   powershell -Command "New-Item -Path 'C:\Windows\System32\Tasks\!TASK_FOLDER!' -ItemType Directory -Force" >nul 2>&1
@REM   echo 文件夹创建完成。
@REM   echo.
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
set "sc_choice="
echo.
set /p "sc_choice=请输入选项编号 [1-7]： "
if "!sc_choice!"=="" set "sc_choice=1"
if "!sc_choice!"=="1" set "sc=ONLOGON"
if "!sc_choice!"=="2" set "sc=ONSTART"
if "!sc_choice!"=="3" set "sc=ONIDLE"
if "!sc_choice!"=="4" set "sc=DAILY"
if "!sc_choice!"=="5" set "sc=WEEKLY"
if "!sc_choice!"=="6" set "sc=MONTHLY"
if "!sc_choice!"=="7" set "sc=ONCE"
if not defined sc (
  echo 无效选项，请重新输入。
  echo.
  goto input_sc
)

@REM ------------------------------------------------------------
@REM 判断需要时间还是延迟
@REM ------------------------------------------------------------
set "need_time=0"
set "need_delay=0"
if "!sc!"=="DAILY" set "need_time=1"
if "!sc!"=="WEEKLY" set "need_time=1"
if "!sc!"=="MONTHLY" set "need_time=1"
if "!sc!"=="ONCE" set "need_time=1"
if "!sc!"=="ONSTART" set "need_delay=1"
if "!sc!"=="ONLOGON" set "need_delay=1"
if "!sc!"=="ONIDLE" set "need_delay=1"

@REM ------------------------------------------------------------
@REM 开始时间
@REM ------------------------------------------------------------
if !need_time! EQU 1 (
  :input_st
  set "st="
  set /p "st=请输入开始时间（如 8:00 或 08:00，直接回车=06:00）： "
  if "!st!"=="" set "st=06:00"
  for /f "tokens=1,2 delims=:" %%a in ("!st!") do (
    set "hour=%%a"
    set "minute=%%b"
  )
  if "!minute!"=="" set "minute=00"
  @REM 验证时间合法性（先校验是否为数字）
  echo !hour!|findstr /r "^[0-9][0-9]*$" >nul
  if !errorlevel! neq 0 (
    echo 小时必须是数字，请重新输入。
    echo.
    goto input_st
  )
  echo !minute!|findstr /r "^[0-9][0-9]*$" >nul
  if !errorlevel! neq 0 (
    echo 分钟必须是数字，请重新输入。
    echo.
    goto input_st
  )
  set /a hour=!hour! 2>nul
  set /a minute=!minute! 2>nul
  if !hour! GEQ 24 (
    echo 小时不能大于23，请重新输入。
    goto input_st
  )
  if !minute! GEQ 60 (
    echo 分钟不能大于59，请重新输入。
    goto input_st
  )
  if !hour! LSS 10 set "hour=0!hour!"
  if !minute! LSS 10 set "minute=0!minute!"
  set "st=!hour!:!minute!"
  echo [自动] 标准化时间： !st!
  set "delay="
  goto :skip_delay
)

@REM ------------------------------------------------------------
@REM 延迟执行
@REM ------------------------------------------------------------
if !need_delay! EQU 1 (
  echo.
  echo 计划类型为 !sc!，支持延迟执行。
  echo.
  set "delay_sec="
  :input_delay
  set /p "delay_sec=请输入延迟秒数（输入数字，如 30 表示 30 秒，直接回车=0）： "
  if "!delay_sec!"=="" set "delay_sec=0"
  echo !delay_sec!|findstr /r "^[0-9][0-9]*$" >nul
  if !errorlevel! neq 0 (
    echo 无效输入，请输入数字。
    echo.
    goto input_delay
  )
  @REM 限制最大秒数（24小时）
  if !delay_sec! GEQ 86400 (
    echo 延迟秒数不能超过 86400（24小时），请重新输入。
    echo.
    goto input_delay
  )

  set /a hours=!delay_sec! / 3600
  set /a remain=!delay_sec! %% 3600
  set /a minutes=!remain! / 60
  set /a seconds=!remain! %% 60
  if !hours! GTR 0 (
    set "display=!hours!时!minutes!分!seconds!秒"
  ) else if !minutes! GTR 0 (
    set "display=!minutes!分!seconds!秒"
  ) else (
    set "display=!seconds!秒"
  )

  @REM 生成符合 schtasks /delay 的格式：mmmm:ss（分钟四位:秒两位）
  set /a total_minutes=!delay_sec! / 60
  set /a remain_sec=!delay_sec! %% 60
  set "minutes_padded=0000!total_minutes!"
  set "minutes_padded=!minutes_padded:~-4!"
  set "seconds_padded=00!remain_sec!"
  set "seconds_padded=!seconds_padded:~-2!"
  set "delay=!minutes_padded!:!seconds_padded!"
  if !delay_sec! EQU 0 set "delay="

  echo [自动] 延迟时间： !delay! ^（即 !display!^）
  echo.
  set "st="
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
set "ru_choice="
set /p "ru_choice=请输入选项编号 [1-3]（直接回车=1）： "
if "!ru_choice!"=="" set "ru_choice=1"
if "!ru_choice!"=="1" (
  set "ru="
  set "rp="
) else if "!ru_choice!"=="2" (
  set "ru=SYSTEM"
  set "rp="
) else if "!ru_choice!"=="3" (
  :input_ru_custom
  set "ru="
  set /p "ru=请输入用户名（格式：域名\用户名）： "
  if "!ru!"=="" (
    echo 用户名不能为空。
    echo.
    goto input_ru_custom
  )
  set "rp="
  set /p "rp=请输入该用户的密码： "
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
echo 即将执行以下命令创建计划任务：
echo.
@REM 简化 /tr 命令，直接使用程序路径（避免引号嵌套问题）
set "tr_cmd=!tr!"
set "cmd=schtasks /create /tn "\!TASK_FOLDER!\!tn!" /tr "!tr_cmd!" /sc !sc! /F /RL HIGHEST"
if not "!st!"=="" set "cmd=!cmd! /st !st!"
if not "!delay!"=="" set "cmd=!cmd! /delay !delay!"
if not "!ru!"=="" set "cmd=!cmd! /ru !ru!"
if not "!rp!"=="" set "cmd=!cmd! /rp !rp!"

echo !cmd!
echo ============================================================
echo.

@REM ------------------------------------------------------------
@REM 确认执行（按 N 返回计划类型选择）
@REM ------------------------------------------------------------
:input_confirm
set "confirm="
set /p "confirm=确认执行？请输入 Y 或 N： "
if /i "!confirm!"=="Y" (
  echo.
  echo 正在创建任务...
  !cmd! >nul 2>&1
  set "errcode=!errorlevel!"
  echo.
  if !errcode! equ 0 (
    echo 任务创建成功，正在应用设置...
    echo.
    @REM 构建将要应用的设置描述
    set "settings_list="
    if /i "!DISABLE_POWER_LIMITS!"=="true" (
      set "settings_list=!settings_list!禁用电池限制（允许电池上运行且不因电池停止）; "
    )
    if /i "!WAKE_TO_RUN!"=="true" (
      set "settings_list=!settings_list!启用唤醒运行; "
    )
    if "!settings_list!"=="" (
      set "settings_list=未应用额外设置"
    )
    echo 将要应用的设置： !settings_list!
    echo.
    @REM 使用 !tn! 引用任务名称
    set "powershell_cmd=try { $task = Get-ScheduledTask -TaskPath '\!TASK_FOLDER!\' -TaskName '!tn!' -ErrorAction Stop; "
    if /i "!DISABLE_POWER_LIMITS!"=="true" (
      set "powershell_cmd=!powershell_cmd! $task.Settings.DisallowStartIfOnBatteries = $false; $task.Settings.StopIfGoingOnBatteries = $false; "
    )
    if /i "!WAKE_TO_RUN!"=="true" (
      set "powershell_cmd=!powershell_cmd! $task.Settings.WakeToRun = $true; "
    )
    set "powershell_cmd=!powershell_cmd! Set-ScheduledTask -InputObject $task; Write-Host '设置已应用' } catch { Write-Host '更新设置失败：' $_.Exception.Message; exit 1 }"
    powershell -Command "!powershell_cmd!"
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
if /i "!confirm!"=="N" (
  @REM 手动清空所有相关变量，实现“重置”效果
  set "sc_choice="
  set "sc="
  set "st="
  set "delay="
  set "ru_choice="
  set "ru="
  set "rp="
  set "need_time=0"
  set "need_delay=0"
  cls
  echo ============================================================
  echo  Windows 计划任务 创建助手
  echo ============================================================
  echo.
  echo [当前路径] !tr!
  echo [任务名称] !tn!
  echo.
  echo 已返回计划类型选择...
  echo.
  timeout /t 1 /nobreak >nul
  goto :input_sc
)
@REM 输入无效，直接重新提示
goto input_confirm
