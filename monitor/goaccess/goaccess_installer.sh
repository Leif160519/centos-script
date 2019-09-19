#!/usr/bin/env bash 
#安装依赖
yum -y install gcc make GeoIP-devel ncurses-devel
wget https://tar.goaccess.io/goaccess-1.3.tar.gz
tar -xzvf goaccess-1.3.tar.gz
cd goaccess-1.3/
./configure --enable-utf8 --enable-geoip=legacy --enable-tcb
make
make install


mkdir -p /usr/local/src/goaccess
touch /usr/local/src/goaccess/goaccess.log
#生成配置文件
cat <<EOF >/usr/local/src/goaccess/goaccess.conf
time-format %H:%M:%S
date-format %d/%b/%Y
log-format %h %^[%d:%t %^] "%r" %s %b "%R" "%u"
real-time-html true
port 7890
#ssl-cert <cert.crt>
#ssl-key <priv.key>
#ws-url wss://<your-domain>:<port>
output /usr/local/src/goaccess/index.html
log-file /usr/local/src/goaccess/goaccess.log
EOF

#生成nginx配置文件
cat <<EOF >/etc/nginx/conf.d/http/7891.conf
server {
    listen 7891;
    root   /usr/local/src/goaccess;
}
EOF

#重新加载nginx配置文件
nginx -s reload


cat <<EOF >/usr/lib/systemd/system/goaccess.service
[Unit]
Description=GoAccess
After=network.target docker.service
[Service]
ExecStart=/usr/local/bin/goaccess --config-file=/usr/local/src/goaccess/goaccess.conf  /var/log/nginx/access.log
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

#启动goaccess
systemctl start goaccess
#添加自动启动
systemctl enable goaccess

exit
