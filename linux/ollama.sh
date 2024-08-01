#!/bin/bash

# 检查并安装 Supervisor（如果未安装）
if ! command -v supervisorctl &> /dev/null; then
    echo "Supervisor 未安装，正在安装..."
    apt-get update
    apt-get install -y supervisor
fi

# 下载或更新 ollama
echo "正在下载或更新 ollama..."
curl -L https://ollama.com/download/ollama-linux-amd64 -o /usr/bin/ollama

# 设置执行权限
chmod +x /usr/bin/ollama

# 检查是否需要创建 Supervisor 配置文件
SUPERVISOR_CONF="/etc/supervisor/conf.d/ollama.conf"
if [ ! -f "$SUPERVISOR_CONF" ]; then
    echo "创建 Supervisor 配置文件..."
    cat <<EOL > $SUPERVISOR_CONF
[program:ollama]
user=root
command=/usr/bin/ollama serve
process_name=%(program_name)s
autostart=true
redirect_stderr=true
stdout_logfile=/var/log/%(program_name)s.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=0
environment=HOME="/root",OLLAMA_HOST="0.0.0.0:11434",OLLAMA_MODELS="/mnt/pub-data/models/ollama/models",OLLAMA_KEEP_ALIVE="720m",OLLAMA_MAX_LOADED_MODELS="2"
EOL
    # 重启 Supervisor 以应用新配置
    supervisorctl reread
    supervisorctl update
    supervisorctl start ollama
else
    # 如果配置文件已经存在，只需重启 ollama 服务
    echo "配置文件已存在，重启 ollama 服务..."
    supervisorctl restart ollama
fi

# 打印 ollama 版本
echo "打印 ollama 版本..."
/usr/bin/ollama --version
