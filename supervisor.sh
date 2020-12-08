#!/bin/bash
echo -e '\033[1;32m 此脚本自动安装supervisor \033[0m'
echo -e '\033[1;32m 安装pip \033[0m'
yum -y install epel-release
yum -y install python-pip
echo -e '\033[1;32m 给pip换源 \033[0m'
mkdir /root/.pip
cat <<EOF >/root/.pip/pip.conf
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host=mirrors.aliyun.com
EOF
echo -e '\033[1;32m 升级pip \033[0m'
pip install --upgrade pip

echo -e '\033[1;32m 安装supervisor \033[0m'
pip install supervisor
echo -e '\033[1;32m 将supervisor配置文件重定向到/etc/目录下面 \033[0m'
mkdir /etc/supervisor
echo_supervisord_conf > /etc/supervisor/supervisord.conf
echo -e '\033[1;32m 新建进程管理文件夹 \033[0m \033[1;33m /etc/supervisor/conf.d \033[0m'
mkdir /etc/supervisor/conf.d
echo -e '\033[1;32m 修改supervisor配置文件(将默认/temp路径放在/var下) \033[0m'
cat <<EOF >/etc/supervisor/supervisord.conf
[unix_http_server]
file=/var/run/supervisor.sock   ; the path to the socket file

[supervisord]
logfile=/var/log/supervisord.log ; main log file; default /supervisord.log
logfile_maxbytes=50MB        ; max main logfile bytes b4 rotation; default 50MB
logfile_backups=10           ; # of main logfile backups; 0 means none, default 10
loglevel=info                ; log level; default info; others: debug,warn,trace
pidfile=/var/run/supervisord.pid ; supervisord pidfile; default supervisord.pid
nodaemon=false               ; start in foreground if true; default false
minfds=1024                  ; min. avail startup file descriptors; default 1024
minprocs=200                 ; min. avail process descriptors;default 200

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock ; use a unix:// URL  for a unix socket

[inet_http_server]         ; inet (TCP) server disabled by default
port=0.0.0.0:9001          ; (ip_address:port specifier, *:port for all iface)
username=admin             ; 用户名 (default is no username (open server))
password=123456            ; 密码 (default is no password (open server))
[include]
files = /etc/supervisor/conf.d/*.conf
EOF
echo -e '\033[1;32m 修改新路径权限 \033[0m'
chmod 777 /var/run
chmor 777 /var/log
echo -e '\033[1;32m 创建supervisor.sock并赋予权限 \033[0m'
touch /var/run/supervisor.sock
chmod 777 /var/run/supervisor.sock
echo -e '\033[1;32m 生成supervisor服务自启动文件,文件路径为: \033[0m \033[1;33m /usr/lib/systemd/system/supervisor.service  \033[0m'
cat <<EOF >/usr/lib/systemd/system/supervisor.service
[Unit]
Description=Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target

[Service]
ExecStart=/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
ExecStop=/usr/bin/supervisorctl $OPTIONS shutdown
ExecReload=/usr/bin/supervisorctl -c /etc/supervisor/supervisord.conf $OPTIONS reload
KillMode=process
Restart=on-failure
RestartSec=50s

[Install]
WantedBy=multi-user.target
EOF

echo -e '\033[1;32m 启动supervisor \033[0m'
systemctl daemon-reload
systemctl start supervisor
echo -e '\033[1;32m 允许开机自启supervisor \033[0m'
systemctl enable supervisor
echo -e '\033[1;32m 管理supervisor下的服务 \033[0m
\033[1;33m
    1.启动服务
    supervisorctl start all
    supervisorctl start service_name
    2.关闭服务
    supervisorctl stop all
    supervisorctl stop service_name
    3.查看状态
    supervisorctl status [service_name]
    4.重新启动所有服务或者是某个服务
    supervisorctl restart all
    supervisorctl restart service_name
    5.关闭supervisor
    supervisorctl shutdown
    6.重新载入supervisor，在这里相当于重启supervisor服务，里面的服务也会跟着重新启动
    supervisorctl reload
    7.添加/删除 要管理服务
    supervisorctl update
\033[0m'
echo -e '\033[1;32m 查看supervisor web管理页面 \033[0m  \033[1;33m http://localhost:9001; 用户名：admin; 密码：123456 \033[0m'
