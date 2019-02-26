#!/bin/bash
echo -e '\033[1;31m ********************************此脚本自动化安装Chrome浏览器******************************** \033[0m'
echo -e "\033[1;31m 安装EPEL安装源 \033[0m"
yum -y install epel-release
echo -e "\033[1;31m 开始安装Chrome浏览器 \033[0m"
yum -y install chromium
exit