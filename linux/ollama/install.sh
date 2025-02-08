!/bin/bash

# 设定默认路径
DEFAULT_OLLAMA_PATH="/mnt/storage/ollama-linux-amd64.tgz"
DEFAULT_MODELS_PATH="/mnt/storage/models"

echo "=== Ollama 安装配置脚本 ==="

# 在开始就询问所有路径
read -p "请输入 ollama-linux-amd64.tgz 的路径 [默认: $DEFAULT_OLLAMA_PATH]: " ollama_path
ollama_path=${ollama_path:-$DEFAULT_OLLAMA_PATH}
if [ ! -f "$ollama_path" ]; then
    echo "错误:文件 $ollama_path 不存在!"
    exit 1
fi

read -p "请输入 models 存放路径 [默认: $DEFAULT_MODELS_PATH]: " models_path
models_path=${models_path:-$DEFAULT_MODELS_PATH}

# 显示确认信息
echo "
将使用以下配置:
- Ollama 文件路径: $ollama_path
- Models 存放路径: $models_path

按回车键继续,或 Ctrl+C 取消..."
read

# 1. 解压 ollama
echo "正在解压 ollama-linux-amd64.tgz..."
tar -C /usr -xzvf "$ollama_path" --overwrite
if [ $? -eq 0 ]; then
    echo "ollama 解压成功"
else
    echo "ollama 解压失败"
    exit 1
fi

# 2. 安装 supervisor
echo "正在更新系统并安装 supervisor..."
apt update
apt install -y supervisor

# 3. 创建 models 目录
echo "创建 models 目录..."
mkdir -p "$models_path"

# 4. 创建 supervisor 配置文件
echo "创建 supervisor 配置文件..."
cat > /etc/supervisor/conf.d/ollama.conf << EOF
[program:ollama]
user=root
command=/usr/bin/ollama serve
process_name=%(program_name)s
autostart=true
redirect_stderr=true
stdout_logfile=/var/log/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=0
environment=HOME="/root",OLLAMA_HOST="0.0.0.0:7860",OLLAMA_LOAD_TIMEOUT=30m,OLLAMA_MODELS="$models_path",OLLAMA_NUM_PARALLEL="3",OLLAMA_MAX_LOADED_MODELS="2",OLLAMA_KEEP_ALIVE="-1"
EOF

# 5. 重新加载 supervisor 并启动 ollama
echo "重新加载 supervisor 配置..."
supervisorctl reread
supervisorctl update
echo "等待服务启动..."
sleep 5  # 等待服务启动

# 6. 添加环境变量到 .bashrc 并立即生效
echo "配置环境变量..."
if ! grep -q "export OLLAMA_HOST=http://localhost:7860" /root/.bashrc; then
    echo "export OLLAMA_HOST=http://localhost:7860" >> /root/.bashrc
    echo "环境变量已添加到 .bashrc"
fi

# 立即生效环境变量
source /root/.bashrc

# 执行 ollama list 并显示结果
echo "执行 ollama list 的结果:"
ollama list

echo "脚本执行完成!"
