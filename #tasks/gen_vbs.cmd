@echo off
setlocal EnableDelayedExpansion

@REM ============================================================
@REM VBS 中转文件生成器
@REM 在目标程序【同目录】生成【同名】.vbs（用 ShellExecute 指定窗口样式）
@REM 供 #1)create.cmd 在 TASK_WINDOW_STYLE=VBS 时调用
@REM 也可独立运行（读取 config.cmd 的 TARGET_PATH）
@REM
@REM 用法：call "%~dp0gen_vbs.cmd" ["程序路径"] [窗口样式0-10] [覆盖标记]
@REM   程序路径缺省时读 config.cmd 的 TARGET_PATH
@REM   窗口样式缺省时读 config.cmd 的 TASK_VBS_STYLE（0-10）
@REM   覆盖标记：非空（如 true）时覆盖前把旧 .vbs 备份为 .vbs.bak，再写入新内容。
@REM             缺省/为空时同样执行备份（统一行为，只保留一份 .bak）。
@REM 成功时设全局变量 VBS_PATH 返回生成的 .vbs 文件路径
@REM ============================================================

@REM ---------- 程序路径：参数优先，否则用配置 ----------
set "TR=%~1"
if not defined TR call "%~dp0config.cmd"
if not defined TR set "TR=!TARGET_PATH!"
if "!TR!"=="" (
  echo [gen_vbs] 错误：未指定程序路径。
  exit /b 1
)
@REM 去除两端的引号
set "TR=!TR:"=!"
if not exist "!TR!" (
  echo [gen_vbs] 错误：程序不存在：!TR!
  exit /b 1
)

@REM ---------- 窗口样式 ----------
set "VBS_STYLE=%~2"
if not defined VBS_STYLE set "VBS_STYLE=!TASK_VBS_STYLE!"
if "!VBS_STYLE!"=="" set "VBS_STYLE=2"

@REM ---------- 覆盖/备份标记（第 3 个参数，仅信息用途） ----------
set "VBS_ALLOW=%~3"
if not defined VBS_ALLOW set "VBS_ALLOW="

@REM ---------- 推导 VBS 路径（同目录同名） ----------
for %%I in ("!TR!") do (
  set "ABS_EXE=%%~fI"
  set "ABS_DIR=%%~dpI"
  set "BASE_NAME=%%~nI"
)
@REM workingDir 去掉末尾反斜杠，避免 VBS 字符串结尾 \" 转义闭引号
set "ABS_DIR_WORK=!ABS_DIR:~0,-1!"
set "VBS_PATH=!ABS_DIR!!BASE_NAME!.vbs"
set "VBS_BAK=!VBS_PATH!.bak"

@REM ---------- 覆盖前备份：旧 .vbs -> .vbs.bak（只保留一份） ----------
if exist "!VBS_PATH!" (
  if exist "!VBS_BAK!" del /q "!VBS_BAK!"
  ren "!VBS_PATH!" "!BASE_NAME!.vbs.bak"
  if errorlevel 1 (
    echo [gen_vbs] 错误：备份原有 VBS 失败：!VBS_PATH!
    exit /b 1
  )
  echo [gen_vbs] 已备份原有 VBS：!VBS_BAK!
)

@REM ---------- 生成 VBS（逐行写入，保持与主脚本一致的编码） ----------
> "%VBS_PATH%" echo Option Explicit
>> "%VBS_PATH%" echo Dim shellApp, exePath, exeArgs, workingDir, windowStyle
>> "%VBS_PATH%" echo Set shellApp = CreateObject^("Shell.Application"^)
>> "%VBS_PATH%" echo exePath  = "!ABS_EXE!"
>> "%VBS_PATH%" echo exeArgs  = ""
>> "%VBS_PATH%" echo workingDir  = "!ABS_DIR_WORK!"
>> "%VBS_PATH%" echo windowStyle = !VBS_STYLE!
>> "%VBS_PATH%" echo shellApp.ShellExecute exePath, exeArgs, workingDir, "", windowStyle

@REM 校验生成成功
if not exist "!VBS_PATH!" (
  echo [gen_vbs] 错误：VBS 生成失败：!VBS_PATH!
  exit /b 1
)
echo [gen_vbs] 已生成：!VBS_PATH!

@REM 通过 endlocal 把结果返回给调用方
endlocal & set "VBS_PATH=%VBS_PATH%"
