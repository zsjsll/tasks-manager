@echo off
@REM ------------------------------------------------------------
@REM 公共配置文件 - 供 create.cmd 和 list.cmd 共同使用
@REM ------------------------------------------------------------

@REM 任务文件夹名称（在计划任务中的路径，如 #self 对应 \#self\）
set "TASK_FOLDER=self"

@REM 是否允许唤醒计算机运行任务 (true/false)
set "WAKE_TO_RUN=false"

@REM 是否禁用电源限制（允许电池上运行且不因电池停止）(true/false)
set "DISABLE_POWER_LIMITS=true"
