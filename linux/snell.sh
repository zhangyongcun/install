#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
apt install -y unzip curl jq
VERSION="v4.0.1"
CONF="/etc/snell/snell-server.conf"
SYSTEMD="/etc/systemd/system/snell.service"
cd ~/
wget --no-check-certificate -O snell.zip https://dl.nssurge.com/snell/snell-server-"$VERSION"-linux-amd64.zip
unzip -o snell.zip
rm -f snell.zip
chmod +x snell-server
mv -f snell-server /usr/local/bin/
if [ -f ${CONF} ]; then
  echo "Found existing config..."
  else
  if [ -z ${PSK} ]; then
    PSK=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
    echo "Using generated PSK: ${PSK}"
  else
    echo "Using predefined PSK: ${PSK}"
  fi
  mkdir -p /etc/snell/
  echo "Generating new config..."
  echo "[snell-server]" >>${CONF}
  echo "listen = 0.0.0.0:7500" >>${CONF}
  echo "psk = ${PSK}" >>${CONF}
  echo "obfs = http" >>${CONF}
fi
if [ -f ${SYSTEMD} ]; then
  echo "Found existing service..."
  systemctl daemon-reload
  systemctl restart snell
else
  echo "Generating new service..."
  echo "[Unit]" >>${SYSTEMD}
  echo "Description=Snell Proxy Service" >>${SYSTEMD}
  echo "After=network.target" >>${SYSTEMD}
  echo "" >>${SYSTEMD}
  echo "[Service]" >>${SYSTEMD}
  echo "Type=simple" >>${SYSTEMD}
  echo "LimitNOFILE=32768" >>${SYSTEMD}
  echo "ExecStart=/usr/local/bin/snell-server -c /etc/snell/snell-server.conf" >>${SYSTEMD}
  echo "" >>${SYSTEMD}
  echo "[Install]" >>${SYSTEMD}
  echo "WantedBy=multi-user.target" >>${SYSTEMD}
  systemctl daemon-reload
  systemctl enable snell
  systemctl start snell
fi

# 获取 IP 信息
ip_data=$(curl -s http://ip-api.com/json)
# 提取 ip 地址和国家简写
ipc=$(echo "$ip_data" | jq -r '.query')
country_code=$(echo "$ip_data" | jq -r '.countryCode')


echo  "================Install Complete ========="
echo "Client Config"
echo "${country_code} = snell, ${ipc}, 7500, psk=${PSK}, obfs=http, version=4"
