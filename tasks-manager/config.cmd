@echo off
@REM ------------------------------------------------------------
@REM 公共配置文件 - 供 create.cmd 和 list.cmd 共同使用
@REM ------------------------------------------------------------

@REM 目标程序路径（若设置，打开 create.cmd 直接使用并跳过输入）
@REM 支持相对路径，将自动以 create.cmd 所在目录为基准转为绝对路径
set "TARGET_PATH="

@REM 任务显示名称（若设置，直接作为任务名使用，与路径独立判断）
set "TASK_NAME="

@REM 任务文件夹名称（在计划任务中的路径，如 #self 对应 \#self\）
set "TASK_FOLDER=@tasks"

@REM 是否禁用电池限制（允许充电时运行）(true/false)
set "DISABLE_POWER_LIMITS=true"

@REM 是否允许唤醒计算机运行任务 (true/false)
set "WAKE_TO_RUN=false"
