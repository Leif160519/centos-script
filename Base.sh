#!/bin/bash
echo -e '\033[1;32m 安装初始环境 \033[0m'
echo -e '\033[1;32m 1.安装常用软件或工具包 \033[0m'
echo -e '\033[1;32m 安装wget \033[0m'
yum -y install wget

function choice(){
    echo -n "是否更换阿里源？(y or n)"
    read choice
    if [[ ${choice} == "y" ]];then
        echo -e '\033[1;32m 2.更换阿里源 \033[0m'
        echo -e '\033[1;32m 备份本地yum源 \033[0m'
        mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak
        echo -e '\033[1;32m 获取阿里yum源配置文件 \033[0m'
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo 
        echo -e '\033[1;32m 更新cache \033[0m'
        yum makecache
        echo -e '\033[1;32m 更新 \033[0m'
        yum -y update
    elif [[ ${choice} == "n" ]];then
        echo "你选择了不更换阿里源"
    else
        echo "输入有误，请重新输入"
        choice
    fi
}
choice

echo -e '\033[1;32m 安装nano \033[0m'
yum -y install nano
echo -e '\033[1;32m 安装zip \033[0m'
yum -y install zip
echo -e '\033[1;32m 安装unzip \033[0m'
yum -y install unzip
echo -e '\033[1;32m 安装git \033[0m'
yum -y install git
echo -e '\033[1;32m 安装java \033[0m'
yum -y install java
echo -e '\033[1;32m 安装yum-utils \033[0m'
yum -y install yum-utils
echo -e '\033[1;32m 安装expect \033[0m'
yum -y install expect
echo -e '\033[1;32m 安装htop \033[0m'
echo -e '\033[1;32m 启用epe版本 \033[0m'
yum -y install epel-release
yum -y install htop
echo -e '\033[1;32m 安装iotop \033[0m'
yum -y install iotop
echo -e '\033[1;32m 安装iftop \033[0m'
yum -y install iftop
echo -e '\033[1;32m 安装nethogs \033[0m'
yum -y install nethogs
echo -e '\033[1;32m 安装mrtg \033[0m'
yum -y install mrtg
echo -e '\033[1;32m 安装nagios \033[0m'
yum -y install nagios
echo -e '\033[1;32m 安装cacti \033[0m'
yum -y install cacti
echo -e '\033[1;32m 安装npm \033[0m'
yum -y install npm
echo -e '\033[1;32m 安装pv \033[0m'
yum -y install pv
echo -e '\033[1;32m 安装telnet \033[0m'
yum -y install telnet
echo -e '\033[1;32m 安装net-tools \033[0m'
yum -y install net-tools
echo -e '\033[1;32m 安装tree \033[0m'
yum -y install tree
echo -e '\033[1;32m 安装tmux \033[0m'
yum -y install tmux
echo -e '\033[1;32m 安装iperf \033[0m'
yum -y install iperf
echo -e '\033[1;32m 安装figlet \033[0m'
yum -y install figlet
echo -e '\033[1;32m 安装lsof \033[0m'
yum -y install lsof
echo -e '\033[1;32m 安装dpkg \033[0m'
yum -y install dpkg
echo -e '\033[1;32m 安装hdparm \033[0m'
yum -y install hdparm
echo -e '\033[1;32m 安装smartmontools \033[0m'
yum -y install smartmontools
echo -e '\033[1;32m 安装psmisc \033[0m'
yum -y install psmisc
echo -e '\033[1;32m 安装fping \033[0m'
yum -y install fping
echo -e '\033[1;32m 安装tcpdump \033[0m'
yum -y install tcpdump
echo -e '\033[1;32m 安装nmap \033[0m'
yum -y install nmap
echo -e '\033[1;32m 安装fio \033[0m'
yum -y install fio
echo -e '\033[1;32m 安装nc \033[0m'
yum -y install nc
echo -e '\033[1;32m 安装strace \033[0m'
yum -y install strace
echo -e '\033[1;32m 安装perf \033[0m'
yum -y install perf
echo -e '\033[1;32m 安装iostat \033[0m'
yum -y install sysstat
systemctl start sysstat && systemctl enable sysstat
echo -e '\033[1;32m 安装dig/nslookup \033[0m'
yum -y install bind-utils
echo -e '\033[1;32m dstat \033[0m'
yum -y install dstat
echo -e '\033[1;32m lynx \033[0m'
yum -y install lynx
echo -e '\033[1;32m w3m \033[0m'
yum -y install w3m
echo -e '\033[1;32m 安装lrzsz \033[0m'
yum -y install lrzsz
echo -e '\033[1;32m 安装monit \033[0m'
yum -y install monit
systemctl start monit && systemctl enable monit
echo -e '\033[1;32m 3.安装时间同步服务器 \033[0m'
yum -y install ntp
echo -e '\033[1;32m 设置开机启动 \033[0m'
systemctl enable ntpd
echo -e '\033[1;32m 启动时间同步服务器 \033[0m'
systemctl start ntpd
echo -e '\033[1;32m 查看时间同步服务器运行状态 \033[0m'
systemctl status ntpd
echo -e '\033[1;32m 设置与windows时间同步 \033[0m'
ntpdate time.windows.com


echo -e '\033[1;32m 4.永久关闭swap分区（重启后生效） \033[0m'
#swapoff -a 临时关闭
sed  -i '/swap/s/^/#/' /etc/fstab


echo -e '\033[1;32m 5.关闭防火墙 \033[0m'
echo -e '\033[1;32m 永久禁用SElinux （重启后生效）\033[0m'
#setenforce 0 临时
echo -e '\033[1;32m 修改 \033[1;33m /etc/selinux/config \033[0m 配置文件 \033[0m'
sed -i "s/enforcing/disabled/g" /etc/selinux/config
echo -e '\033[1;32m 查看selinux状态\033[0m 配置文件 \033[0m'
sestatus
getenforce
echo -e '\033[1;32m 停止防火墙服务 \033[0m'
systemctl stop firewalld
echo -e '\033[1;32m 禁止防火墙开机自启 \033[0m'
systemctl disable firewalld


echo -e '\033[1;32m 6.安装screenfetch \033[0m'
echo -e '\033[1;32m 从github上下载screenfetch \033[0m'
git clone git://github.com/KittyKatt/screenFetch.git screenfetch
echo -e '\033[1;32m 复制文件到/usr/bin/目录 \033[0m'
cp screenfetch/screenfetch-dev /usr/bin/screenfetch
echo -e '\033[1;32m 给screenfetch赋予可执行权限 \033[0m'
chmod +x /usr/bin/screenfetch
echo -e '\033[1;32m 查看计算机软硬件信息 \033[0m'
screenfetch


# curl -o screenfetch.zip https://codeload.github.com/KittyKatt/screenFetch/zip/master
# unzip screenfetch.zip
# cp screenFetch-master/screenfetch-dev /usr/local/bin/screenfetch
# chmod +x /usr/local/bin/screenfetch
# screenfetch

echo -e '\033[1;32m 7.安装neofetch \033[0m'
curl -o /etc/yum.repos.d/konimex-neofetch-epel-7.repo https://copr.fedorainfracloud.org/coprs/konimex/neofetch/repo/epel-7/konimex-neofetch-epel-7.repo
yum -y install neofetch
neofetch


echo -e '\033[1;32m 8.关闭SSH DNS反向解析和GSSAPI的用户认证 \033[0m'
sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config
sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g" /etc/ssh/sshd_config
echo -e '\033[1;32m 解决SSH掉线问题 \033[0m'
sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 60/g" /etc/ssh/sshd_config
sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 60/g" /etc/ssh/sshd_config
echo -e '\033[1;32m 重启sshd服务 \033[0m'
systemctl restart sshd
echo -e '\033[1;32m 查看sshd服务状态 \033[0m'
systemctl status sshd


# echo "修复重启后网络服务无法启动的问题"
# systemctl stop NetworkManager
# systemctl disable NetworkManager
# Systemctl start network

echo -e '\033[1;32m系统初始化配置完成！\033[0m'
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all

function choose_reboot(){
    echo -n "是否重启？(y or n)"
    read choice
    if [[ ${choice} == "y" ]];then
        echo -e '\033[1;32m 你选择了重启 \033[0m'
        reboot
    elif [[ ${choice} == "n" ]];then
        echo "你选择了不重启"
    else
        echo "输入有误，请重新输入"
        choice
    fi
}
choose_reboot
exit
