@echo off
@REM ------------------------------------------------------------
@REM 公共配置文件 - 供 create.cmd 和 list.cmd 共同使用
@REM 以下变量按【交互顺序】排列，留空则脚本进入交互式填写
@REM ------------------------------------------------------------

@REM ① 目标程序路径（第一个交互项）
@REM    若设置，打开 create.cmd 直接使用并跳过输入；支持相对路径，
@REM    将自动以 create.cmd 所在目录为基准转为绝对路径
set "TARGET_PATH="

@REM ② 任务显示名称（第二个交互项）
@REM    若设置，直接作为任务名使用，与路径独立判断
set "TASK_NAME="

@REM ③ 计划类型（第三个交互项）
@REM    取值： ONLOGON / ONSTART / ONIDLE / DAILY / WEEKLY / MONTHLY / ONCE
@REM    留空则进入交互式选择
set "TASK_SCHEDULE_TYPE="

@REM ④ 开始时间（第四个交互项）
@REM    格式：时:分，如 08:00
@REM    格式：时，如 8
@REM    仅对需要时间的计划类型（DAILY/WEEKLY/MONTHLY/ONCE）生效
@REM    留空则进入交互式输入
set "TASK_START_TIME="

@REM ⑤ 延迟秒数（第五个交互项）
@REM    数字（秒），如 30 表示 30 秒
@REM    仅对支持延迟的计划类型（ONLOGON/ONSTART/ONIDLE）生效
@REM    留空则进入交互式输入
set "TASK_DELAY_SECONDS="

@REM ⑥ 运行账户（第六个交互项）
@REM    CURRENT=当前用户 / SYSTEM=系统账户 / 其它值=自定义用户名
@REM    留空则进入交互式选择
set "TASK_RUN_USER=CURRENT"

@REM ⑦ 运行账户密码
@REM    仅当 TASK_RUN_USER 为自定义用户名时使用
set "TASK_RUN_PASSWORD="

@REM ------------------------------------------------------------
@REM 以下为固定配置
@REM ------------------------------------------------------------

@REM 任务文件夹名称（在计划任务中的路径，如 #self 对应 \#self\）
set "TASK_FOLDER=@tasks"

@REM 是否禁用电池限制（允许充电时运行）(true/false)
set "DISABLE_POWER_LIMITS=true"

@REM 是否允许唤醒计算机运行任务 (true/false)
set "WAKE_TO_RUN=false"
