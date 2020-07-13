#!/bin/bash
#master、etcd、node节点初始化安装
master_ip=${1:-"192.168.81.51"}
etcd_ip=${2:-"192.168.81.52"}
node1_ip=${3:-"192.168.81.53"}
prefix=${4:-"k8s"}
#切换阿里的yum源
#安装wget
yum install -y wget
#切换yum源
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache
#安装网络工具
yum install -y net-tools

#关闭防火墙
systemctl stop firewalld & systemctl disable firewalld

#关闭swap
#临时关闭
swapoff -a
#永久关闭,重启后生效
sed -i '/ swap / s/^/#/' /etc/fstab


#配置docker源
yum -y install yum-utils
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache

#关闭selinux
#获取状态
getenforce
#暂时关闭
setenforce 0
#永久关闭 需重启
sed -i "s/enforcing/disabled/g" /etc/selinux/config

#设置host
echo "${master_ip} ${prefix}.master" >> /etc/hosts
echo "${master_etcd} ${prefix}.etcd" >> /etc/hosts
echo "${master_node1} ${prefix}.node1" >> /etc/hosts
cat <<EOF >/etc/hostname
${prefix}.etcd
EOF

#1.初始化安装后先进行etcd的安装
#搭建etcd
#下载etcd
yum -y install etcd
#配置config
sed -i "/^ETCD_LISTEN_CLIENT_URLS=/cETCD_LISTEN_CLIENT_URLS=\"http://0.0.0.0:2379\"" /etc/etcd/etcd.conf
sed -i "/^ETCD_ADVERTISE_CLIENT_URLS=/cETCD_ADVERTISE_CLIENT_URLS=\"http://${prefix}.etcd:2379\"" /etc/etcd/etcd.conf

#运行etcd
#设置开机启动 且启动服务
systemctl enable etcd && systemctl start etcd
#查看服务状态
netstat -nlp | grep etcd


#配置etcd内网信息
#设置 (就像定义一个变量一样)
etcdctl -C http://${etcd_ip}:2379 set /atomic.io/network/config '{"Network":"172.17.0.0/16"}' 
#获取
etcdctl -C http://${etcd_ip}:2379 get /atomic.io/network/config
exit