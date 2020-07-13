#!/bin/bash
echo -e '\033[1;32m 安装Chrome浏览器 \033[0m'
echo -e "\033[1;32m 安装EPEL安装源 \033[0m"
yum -y install epel-release
echo -e "\033[1;32m 开始安装Chrome浏览器 \033[0m"
yum -y install chromium
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all
exit
