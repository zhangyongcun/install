#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误：请使用root权限运行此脚本！${NC}"
    echo -e "${YELLOW}请尝试: sudo $0${NC}"
    exit 1
fi

echo -e "${BLUE}====================================${NC}"
echo -e "${GREEN}SSH登录Bark通知设置工具${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${YELLOW}此工具将设置在SSH登录时发送Bark通知${NC}"
echo ""

# 请求Bark ID
echo -e "${GREEN}请输入您的Bark ID/Token:${NC}"
read BARK_TOKEN

if [ -z "$BARK_TOKEN" ]; then
    echo -e "${RED}未提供Bark Token，退出安装。${NC}"
    exit 1
fi

# 创建通知脚本
echo -e "${YELLOW}正在创建通知脚本...${NC}"

cat > /usr/local/bin/ssh_login_notify.sh << EOF
#!/bin/bash

# Bark通知URL
BARK_TOKEN="$BARK_TOKEN"
BARK_BASE_URL="https://api.day.app"

# 获取登录信息
USER=\${PAM_USER:-\$(whoami)}
RHOST=\${PAM_RHOST:-"手动执行"}
SERVICE=\${PAM_SERVICE:-"manual"}
TTY=\${PAM_TTY:-\$(tty)}
DATE=\$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=\$(hostname)

# 构建通知消息
TITLE="SSH登录提醒"
BODY="服务器：\$HOSTNAME
用户：\$USER
来源IP：\$RHOST
终端：\$TTY
时间：\$DATE"

# 发送通知，设置3秒超时并将所有输出重定向到/dev/null
curl -s -m 3 -X POST \\
  "\$BARK_BASE_URL/\$BARK_TOKEN/" \\
  --data-urlencode "title=\$TITLE" \\
  --data-urlencode "body=\$BODY" > /dev/null 2>&1

# 无论curl是否成功，都返回成功状态，确保不影响SSH登录
exit 0
EOF

# 设置执行权限
chmod +x /usr/local/bin/ssh_login_notify.sh

echo -e "${YELLOW}正在配置PAM模块...${NC}"

# 检查PAM配置文件是否存在
PAM_FILE="/etc/pam.d/sshd"
if [ ! -f "$PAM_FILE" ]; then
    echo -e "${RED}找不到PAM配置文件: $PAM_FILE${NC}"
    echo -e "${RED}您的系统可能使用不同的PAM配置。请手动配置。${NC}"
    exit 1
fi

# 检查是否已经配置了通知
if grep -q "ssh_login_notify.sh" "$PAM_FILE"; then
    echo -e "${YELLOW}PAM配置中已存在登录通知设置，将跳过此步骤。${NC}"
else
    # 添加PAM配置，使用nohup确保不阻塞登录过程
    echo "session optional pam_exec.so seteuid /usr/local/bin/ssh_login_notify.sh" >> "$PAM_FILE"
    echo -e "${GREEN}已成功添加PAM配置。${NC}"
fi

# 重启SSH服务
echo -e "${YELLOW}正在重启SSH服务...${NC}"

# 检测系统类型并重启对应的SSH服务
if systemctl status sshd &>/dev/null; then
    systemctl restart sshd
    echo -e "${GREEN}已重启sshd服务。${NC}"
elif systemctl status ssh &>/dev/null; then
    systemctl restart ssh
    echo -e "${GREEN}已重启ssh服务。${NC}"
else
    echo -e "${YELLOW}无法自动重启SSH服务，请手动重启。${NC}"
    echo -e "${YELLOW}您可以尝试: sudo service sshd restart 或 sudo service ssh restart${NC}"
fi

# 测试通知
echo -e "${BLUE}====================================${NC}"
echo -e "${GREEN}设置完成！${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${YELLOW}是否要发送测试通知？(y/n)${NC}"
read TEST_NOTIFY

if [[ "$TEST_NOTIFY" == "y" || "$TEST_NOTIFY" == "Y" ]]; then
    echo -e "${YELLOW}正在发送测试通知...${NC}"
    # 测试时使用timeout命令确保不会长时间等待
    timeout 4 /usr/local/bin/ssh_login_notify.sh
    echo -e "${GREEN}测试通知已发送，请检查您的Bark应用。${NC}"
    echo -e "${YELLOW}(如果Bark服务器无响应，通知可能发送失败，但不会影响SSH登录)${NC}"
fi

echo -e "${GREEN}下次SSH登录时，您将收到登录通知。${NC}"
echo -e "${YELLOW}注意：以下情况可能不会触发通知：${NC}"
echo -e "${YELLOW}1. 使用密钥登录且没有交互式会话${NC}"
echo -e "${YELLOW}2. Bark服务器无响应或超过3秒超时${NC}"
echo -e "${YELLOW}3. 网络连接问题${NC}"
echo -e "${GREEN}这些情况下SSH登录仍会正常进行，只是通知可能失败。${NC}"
