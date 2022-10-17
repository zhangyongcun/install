mkdir opt/ddns
cd opt/ddns
wget https://github.com/TimothyYe/godns/releases/download/v2.9.0/godns_2.9.0_Linux_x86_64.tar.gz
tar -zxvf godns_2.9.0_Linux_x86_64.tar.gz
echo "{
  \"provider\": \"Cloudflare\",
  \"login_token\": \"WBOKs*********************GJ\",
  \"domains\": [{
      \"domain_name\": \"google.com\",
      \"sub_domains\": [\"help\"]
    }
  ],
  \"resolver\": \"8.8.8.8\",
  \"ip_urls\": [\"https://ipinfo.io/ip\"],
  \"ip_type\": \"IPv4\",
  \"interval\": 300,
  \"socks5_proxy\": \"\"
}" > config.json

echo "[Unit]
Description=Snell Proxy Service
After=network.target

[Service]
Type=simple
LimitNOFILE=32768
ExecStart=/usr/local/bin/snell-server -c /etc/snell/snell-server.conf

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/ddns.service

echo "[Unit]
Description=Snell Proxy Service
After=network.target

[Service]
Type=simple
LimitNOFILE=32768
ExecStart=/opt/ddns/godns -c /opt/ddns/config.json

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/ddns.service

systemctl enable ddns.service
systemctl start ddns.service