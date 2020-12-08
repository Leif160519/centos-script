#!/bin/bash
echo -e '\033[1;32m 1.永久关闭swap分区（重启后生效） \033[0m'
#swapoff -a 临时关闭
sed  -i '/swap/s/^/#/' /etc/fstab

echo -e '\033[1;32m 2.关闭防火墙 \033[0m'
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

echo -e '\033[1;32m 3.关闭SSH DNS反向解析和GSSAPI的用户认证 \033[0m'
sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config
sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g" /etc/ssh/sshd_config
echo -e '\033[1;32m 解决SSH掉线问题 \033[0m'
sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 60/g" /etc/ssh/sshd_config
sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 60/g" /etc/ssh/sshd_config
echo -e '\033[1;32m 重启sshd服务 \033[0m'
systemctl restart sshd

echo -e '\033[1;32m 4.设置所有sudo指令不需要密码 \033[0m'
sed "/^%wheel/c%wheel   ALL=(ALL)       NOPASSWD:ALL" /etc/sudoers

echo -e '\033[1;32m 5.给pip换源 \033[0m'
mkdir -p /root/.pip
cat <<EOF > /root/.pip/pip.conf
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host=mirrors.aliyun.com
EOF

echo -e '\033[1;32m 6.配置vim \033[0m'
cat <<EOF >> /etc/vimrc
set foldmethod=marker
highlight RedundantSpaces ctermbg=red guibg=red
match RedundantSpaces /\s\+$\| \+\ze\t\|\t/
set tabstop=4
set shiftwidth=4
set expandtab
set softtabstop=4
set fileformats=unix
EOF

echo -e '\033[1;32m 7.配置关机等待时间 \033[0m'
sed -i "/^#DefaultTimeoutStartSec/cDefaultTimeoutStartSec=10s" /etc/systemd/system.conf
sed -i "/^#DefaultTimeoutStopSec/cDefaultTimeoutStopSec=10s" /etc/systemd/system.conf


function choose_reboot(){
    echo -n "是否重启？(y or n)"
    read -r choice
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
