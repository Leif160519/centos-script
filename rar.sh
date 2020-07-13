#!/usr/bin/env bash 
sys_info=`uname -a`
echo "下载安装包并解压"
if [[ ${sys_info} =~ 64 ]];then
    wget -c http://www.rarlab.com/rar/rarlinux-x64-5.7.1.tar.gz
    tar -zxvf rarlinux-x64-5.7.1.tar.gz
else 
    wget -c http://www.rarsoft.com/rar/rarlinux-5.7.1.tar.gz
    tar -zxvf rarlinux-5.7.1.tar.gz
fi
echo "进入文件夹"
cd rar
echo "编译和安装"
make
echo "测试"
rar
exit
