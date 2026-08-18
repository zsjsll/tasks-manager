# create-tasks

## #startup

1. 创建一个程序的 vbs, 用于控制程序的启动方式
2. 并创建这个vbs的 快捷方式 复制到 `shell:startup` 中, 用于开机启动


## #tasks

通过系统自带的 `taskschd.msc` 创建任务

可以实现 定时执行 或者 开机执行 等需求

在#tasks 下 创建vbs 如果 vbs同名了 会怎么办 ?
如果出现同名文件, 我希望给我提示 强制执行(直接覆盖) 或是 退出程序(手动处理)
