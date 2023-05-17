#!/bin/bash
echo -e '\033[1;32m 安装cockpit \033[0m'
yum -y install cockpit
echo -e '\033[1;32m 设置开机自启 \033[0m'
systemctl enable --now cockpit.socket
# echo -e '\033[1;32m 防火墙处理 \033[0m'
# firewall-cmd --permanent --zone=public --add-service=cockpit
# firewall-cmd --reload
echo -e '\033[1;32m 启动cockpit \033[0m'
systemctl start cockpit
echo -e '\033[1;32m 访问http://localhost:9090；使用本机用户名和密码登录 \033[0m'
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all
exit
