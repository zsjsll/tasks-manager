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
@REM    必须是【纯数字】秒数，如 30 表示 30 秒、0 表示不延迟
@REM    注意：填非数字（如 1.txt 之类）会导致校验失败报"无效输入"
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

@REM 程序窗口启动方式
@REM    MINIMIZED=最小化启动（用 cmd /c start "" /min 包装）
@REM    VBS=通过 VBS 中转指定窗口样式（功能最全，见下方 TASK_VBS_STYLE）
@REM    NORMAL / 留空 / 其它=正常启动（直接执行程序）
set "TASK_WINDOW_STYLE=MINIMIZED"

@REM 当 TASK_WINDOW_STYLE=VBS 时生效：ShellExecute 的窗口样式（0-10 数字）
@REM   0=隐藏  1=还原  2=最小化  3=最大化  4/5/6/7/8/9/10=其他各种显示方式
@REM   （与 #startup 文件夹 cfg.cmd 的 WINDOW_STYLE 一致）
@REM 0 隐藏窗口并激活另一个窗口
@REM 1 激活并显示窗口，还原为原始大小位置
@REM 2 激活窗口并将其显示为最小化
@REM 3 激活窗口并将其显示为最大化
@REM 4 按最近大小位置显示，不激活
@REM 5 以当前状态激活并显示窗口
@REM 6 最小化指定窗口并激活下一个顶层窗口
@REM 7 最小化显示，保持当前活动窗口
@REM 8 以当前状态显示，不激活
@REM 9 激活并显示窗口，还原最小化/最大化
@REM 10 根据程序启动信息设定的状态显示

set "TASK_VBS_STYLE=7"

@REM 是否在删除任务时同步删除对应的 VBS 文件 (true/false)
set "DELETE_VBS_ON_REMOVE=false"

@REM 是否禁用电池限制（允许充电时运行）(true/false)
set "DISABLE_POWER_LIMITS=true"

@REM 是否允许唤醒计算机运行任务 (true/false)
set "WAKE_TO_RUN=false"

@REM ------------------------------------------------------------
@REM 运行结束后的行为控制（供 #1)create.cmd 使用）
@REM ------------------------------------------------------------
@REM 任务创建完成并显示结果后：
@REM   RUN_LOOP=true  = 按任意键【回到主界面】继续采集/创建下一个任务（默认）
@REM   RUN_LOOP=false = 按任意键【退出】程序
set "RUN_LOOP=true"
