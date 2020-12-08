#!/bin/bash
echo -e '\033[1;32m 安装MongoDB \033[0m'
echo -e '\033[1;32m 添加MongoDB源 \033[0m'
cat <<EOF > /etc/yum.repos.d/mongodb-org-4.0.repo
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF
echo -e '\033[1;32m 安装MongoDB \033[0m'
yum install -y mongodb-org
echo -e '\033[1;32m 开启MongoDB远程访问 \033[0m'
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
echo -e '\033[1;32m 启动MongoDB \033[0m'
systemctl start mongod.service
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all
exit
