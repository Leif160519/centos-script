#!/bin/bash
echo -e "\033[1;31m  此脚本设置有线网连接,请以root用户执行 \033[0m"
echo -e "\033[1;32m  查看IP状态 \033[0m"
ip a
read -rp "请输入网卡设备号:" interface
read -rp "请输入有线IP地址:" address
read -rp "请输入有线子网掩码(24):" netmask
read -rp "请输入有线网关:" gateway
read -rp "请输入有线DNS1(必填):" dns1
read -rp "请输入有线DNS2(若没有直接回车跳过):" dns2

uuid=$(uuidgen)
cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-"${interface}"
TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
BOOTPROTO="none"
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_FAILURE_FATAL="no"
IPV6_ADDR_GEN_MODE="stable-privacy"
NAME="${interface}"
UUID="${uuid}"
DEVICE="${interface}"
ONBOOT="yes"
IPADDR="${address}"
PREFIX="${netmask}"
GATEWAY="${gateway}"
IPV6_PRIVACY="no"
DNS1="${dns1}"
DNS2="${dns2}"
EOF

echo -e "\033[1;32m  重启网络服务 \033[0m"
systemctl restart network
echo -e '\033[1;32m 查看修改后的IP地址 \033[0m'
ip a
exit
