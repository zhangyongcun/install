#!/bin/bash

# 1. 检查是否以 root 用户运行，检查 nginx 安装
if [ "$(id -u)" != "0" ]; then
  echo "请以 root 用户运行此脚本。"
  exit 1
fi

if ! command -v nginx >/dev/null 2>&1; then
  echo "Nginx 未安装，正在安装..."
  apt-get update
  apt-get install -y nginx
fi

# 2. 交互
read -p "请输入要绑定的域名: " domain
read -p "请输入要绑定的端口 (默认: 80): " port
read -p "请输入要转发的内网地址 (以 http:// 开头): " proxy_pass
if [ -z "$port" ]; then
  port="80"
fi
if [ "$port" == "443" ]; then
  default_protocol="https"
else
  default_protocol="http"
fi
read -p "请选择协议 (http/https) (默认: $default_protocol): " protocol
if [ -z "$protocol" ]; then
  protocol="$default_protocol"
fi

# 3. 如果是 http 协议
if [ "$protocol" == "http" ]; then
  config_file="/etc/nginx/conf.d/${domain}.conf"
  cat > "$config_file" <<- EOM
server {
        listen ${port};
        server_name ${domain};

        access_log /var/log/nginx/${domain}.log;
        error_log /var/log/nginx/${domain}.error.log;

        location / {
                proxy_set_header Host \$host;
                proxy_cache off;
                proxy_buffering off;
                chunked_transfer_encoding on;
                tcp_nopush on;
                tcp_nodelay on;
                keepalive_timeout 300;
                proxy_pass ${proxy_pass};
        }
}
EOM
# 4. 如果是 https
else
  ssl_directory="/etc/nginx/ssl/${domain}"
  mkdir -p "$ssl_directory"
  ssl_certificate="${ssl_directory}/${domain}.pem"
  ssl_certificate_key="${ssl_directory}/${domain}.key"

  if [ ! -f "$ssl_certificate" ] || [ ! -f "$ssl_certificate_key" ]; then
    echo "请将 SSL 证书文件放置在以下路径:"
    echo "证书: ${ssl_certificate}"
    echo "私钥: ${ssl_certificate_key}"
    exit 1
  fi

  config_file="/etc/nginx/conf.d/${domain}.conf"
  cat > "$config_file" <<- EOM
server {
        listen 443 ssl;
        server_name ${domain};
        client_max_body_size 32m;
        ssl_certificate ${ssl_certificate};
        ssl_certificate_key ${ssl_certificate_key};

        access_log /var/log/nginx/${domain}.log;
        error_log /var/log/nginx/${domain}.error.log;

        location / {
                proxy_set_header Host \$host;
                proxy_cache off;
                proxy_buffering off;
                chunked_transfer_encoding on;
                tcp_nopush on;
                tcp_nodelay on;
                keepalive_timeout 300;
                proxy_pass ${proxy_pass};
        }
}

server {
        listen 80;
        server_name ${domain};
        return 301 https://\$server_name\$request_uri;
}
EOM
fi

# 检查 Nginx 配置
nginx_test_output=$(nginx -t 2>&1)
if echo "$nginx_test_output" | grep -q "test is successful"; then
  nginx -s reload
  echo "配置完成，Nginx 已重载。"
else
  echo "Nginx 配置测试失败，请检查配置文件。"
  echo "$nginx_test_output"
  exit 1
fi