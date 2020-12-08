#!/bin/bash
echo -e '\033[1;32m 6.安装rar \033[0m'
sys_info=$(uname -a)
echo "下载安装包并解压"
if [[ ${sys_info} =~ 64 ]];then
    wget -c http://www.rarlab.com/rar/rarlinux-x64-5.7.1.tar.gz
    tar -zxvf rarlinux-x64-5.7.1.tar.gz
else
    wget -c http://www.rarsoft.com/rar/rarlinux-5.7.1.tar.gz
    tar -zxvf rarlinux-5.7.1.tar.gz
fi
cd rar || exit
make

exit
