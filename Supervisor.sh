#!/bin/bash
echo -e '\033[1;31m ********************************此脚本自动化部署supervisor******************************** \033[0m'
echo -e '\033[1;31m 设置supervisor自启动脚本 \033[0m'
cat <<EOF >/etc/supervisor/conf.d/eureka-server.conf
[program:eureka-server]
command=java -jar /root/eureka-server-0.0.1-SNAPSHOT.jar --spring.profiles.active=peer1
directory=/root
user=root
stdout_logfile=/var/log/eureka-server.log
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF
echo -e '\033[1;31m 使用以下命令操作supervisor：\033[0m 
\033[1;33m
 supervisor> reload
 supervisor> status
\033[0m'
echo -e '\033[1;32m eureka注册中心配置完成！\033[0m'
exit
