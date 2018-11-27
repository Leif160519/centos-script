#!/bin/bash
echo -e '\033[1;31m ********************************此脚本自动化安装Docker&docker-compose******************************** \033[0m'
echo -e '\033[1;31m 4.安装Docker \033[0m'
echo -e '\033[1;31m 添加Docker源 \033[0m'
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
echo -e '\033[1;31m 更新源 \033[0m'
yum makecache
echo -e '\033[1;31m 安装docker-ce \033[0m'
yum install -y docker-ce
echo -e '\033[1;31m 设置Docker开机自启动 \033[0m'
systemctl enable docker
echo -e '\033[1;31m 启动docker \033[0m'
systemctl start docker 
echo -e '\033[1;31m 查看docker服务启动状态 \033[0m'
systemctl status docker 
echo -e '\033[1;31m 查看docker版本 \033[0m'
docker version 
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 5.安装docker-compose \033[0m'
scp luofei@192.168.81.29:Downloads/docker-compose-Linux-x86_64 /usr/local/bin
echo -e '\033[1;31m 重命名 \033[0m'
mv /usr/local/bin/docker-compose-Linux-x86_64 /usr/local/bin/docker-compose
echo -e '\033[1;31m 添加执行权限 \033[0m'
chmod +x /usr/local/bin/docker-compose
echo -e '\033[1;31m 查看docker-compose版本 \033[0m'
docker-compose version
echo -e '\033[1;31m ********************************************************************************** \033[0m'
exit