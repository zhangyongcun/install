#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
# download
VERSION="v4.0.1"
wget --no-check-certificate -O snell.zip https://github.com/surge-networks/snell/releases/download/"$VERSION"/snell-server-"$VERSION"-linux-amd64.zip
unzip -o snell.zip
rm -f snell.zip
systemctl stop snell.service
mv -f snell-server /usr/local/bin/
chmod +x /usr/local/bin/snell-server
systemctl start snell.service
sysctl -w net.core.rmem_max=26214400
sysctl -w net.core.rmem_default=26214400
