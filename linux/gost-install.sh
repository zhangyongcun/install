#!/bin/bash

# 获取最新版本号
latest_version=$(curl -s https://api.github.com/repos/ginuerzh/gost/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
formatted_version=$(echo "$latest_version" | sed 's/^v//')

# 构建下载链接并下载压缩文件
download_url="https://github.com/ginuerzh/gost/releases/download/$latest_version/gost-linux-amd64-$formatted_version.gz"
curl -L -o gost-linux-amd64-$formatted_version.gz $download_url

# 解压缩并重命名
gzip -d gost-linux-amd64-$formatted_version.gz
mv gost-linux-amd64-$formatted_version gost

# 移动到 /usr/local/bin 并添加可执行权限
mv gost /usr/local/bin
chmod +x /usr/local/bin/gost

# 验证安装并打印 gost 版本号
gost -v
