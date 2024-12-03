#!/bin/bash

# 下载Aspera CLI安装脚本
wget https://raw.githubusercontent.com/zhangyongcun/install/main/linux/ibm-aspera-cli-3.9.6.1467.159c5b1-linux-64-release.sh

# 添加执行权限
chmod +x ibm-aspera-cli-3.9.6.1467.159c5b1-linux-64-release.sh

# 执行安装脚本
./ibm-aspera-cli-3.9.6.1467.159c5b1-linux-64-release.sh

# 将PATH导出命令追加到.bashrc文件
echo 'export PATH=/root/.aspera/cli/bin:$PATH' >> /root/.bashrc

# 使新的PATH设置生效
source /root/.bashrc

# 执行ascp -h命令
ascp -h
