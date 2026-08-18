@echo off
setlocal EnableDelayedExpansion

REM ===== 引入公共配置 =====
call "%~dp0cfg.cmd"

echo.
if exist "!ShortcutPath!" (
  del /F /Q "!ShortcutPath!"
  echo 已删除启动快捷方式：!ShortcutPath!
  ) else (
  echo 未找到快捷方式：!ShortcutPath!
)
echo.
if exist "!ABS_VBS_PATH!" (
  del /F /Q "!ABS_VBS_PATH!"
  echo 已删除 VBS：!ABS_VBS_PATH!
  ) else (
  echo 未找到 VBS：!ABS_VBS_PATH!
)

echo.
pause
endlocal
