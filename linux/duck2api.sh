#!/bin/bash

# 下载 duck2api 并解压到 /opt/duck2api
wget https://github.com/aurora-develop/Duck2api/releases/download/v2.1.0/duck2api-linux-amd64.tar.gz -O /tmp/duck2api-linux-amd64.tar.gz
mkdir -p /opt/duck2api
tar -xzf /tmp/duck2api-linux-amd64.tar.gz -C /opt/duck2api

# 生成随机的 Authorization 字符串
AUTHORIZATION=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)

# 创建 systemd service 文件
cat <<EOF >/etc/systemd/system/duck2api.service
[Unit]
Description=Duck2API Service

[Service]
ExecStart=/opt/duck2api/duck2api
Environment="Authorization=$AUTHORIZATION"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启动服务
systemctl daemon-reload
systemctl enable duck2api.service
systemctl start duck2api.service

# 获取本机公网 IP
PUBLIC_IP=$(curl -s ifconfig.me)

# 打印信息
echo "请求地址：http://$PUBLIC_IP:8080/"
echo "Authorization: $AUTHORIZATION"

# 输出测试命令
echo "curl http://$PUBLIC_IP:8080/v1/chat/completions -H \"Content-Type: application/json\" -H \"Authorization: Bearer $AUTHORIZATION\" -d '{\"model\": \"gpt-4o-mini\", \"messages\": [{\"role\": \"user\", \"content\": \"python send http request\"}], \"temperature\": 0.7}'"