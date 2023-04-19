#!/bin/bash

# 检查 supervisord 是否已安装，如果没有则进行安装
if ! [ -x "$(command -v supervisorctl)" ]; then
  echo 'Supervisor is not installed, installing now...'
  apt-get update
  apt-get install -y supervisor
fi

# 交互式 shell，获取程序运行目录、命令、程序名
read -p "Enter the program's execution directory (default is empty): " directory
read -p "Enter the program's execution command: " command
read -p "Enter the program's name: " program_name

# 创建 Supervisor 配置文件
config_file="/etc/supervisor/conf.d/${program_name}.conf"
touch $config_file
chmod 644 $config_file

# 写入配置文件内容
echo "[program:${program_name}]
user=root" >> $config_file
if [ -n "$directory" ]; then
  echo "directory=$directory" >> $config_file
fi
echo "command=$command
process_name=%(program_name)s
autostart=true
redirect_stderr=true
stdout_logfile=/var/log/%(program_name)s.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=0" >> $config_file

# 重启 Supervisor 服务以使配置文件生效
supervisorctl reread
supervisorctl update

# 延迟2秒，等待程序被Supervisor正确启动
sleep 2

# 验证该程序是否已经被添加到 supervisor
if supervisorctl status ${program_name} | grep -q "RUNNING";
then
    echo "Program ${program_name} has been added to Supervisor successfully."
else
    echo "Failed to add ${program_name} to Supervisor."
fi
