#!/bin/bash
echo -e '\033[1;31m ********************************此脚本自动化安装MongoDB******************************** \033[0m'
echo -e '\033[1;31m ********************************添加MongoDB源******************************** \033[0m'
cat <<EOF > /etc/yum.repos.d/mongodb-org-4.0.repo
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF
echo -e '\033[1;31m 安装MongoDB \033[0m'
yum install -y mongodb-org
echo -e '\033[1;31m 启动MongoDB \033[0m'
systemctl start mongod.service
echo -e '\033[1;31m 查看MongoDB状态 \033[0m'
systemctl status mongod.service
exit
