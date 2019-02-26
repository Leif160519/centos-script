#!/bin/bash
echo -e '\033[1;31m ********************************此脚本自动化安装Chrome浏览器******************************** \033[0m'
echo "\033[1;31m 生成Chrome依赖文件 \033[0m"
cat <<EOF > /ect/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF
echo "\033[1;31m 开始安装Chrome浏览器 \033[0m"
yum -y install google-chrome-stable --nogpgcheck