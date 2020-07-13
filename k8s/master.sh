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
${prefix}.master
EOF

#2.etcd安装完成后再执行master节点的安装
#安装服务
yum -y install kubernetes-master
#配置config
sed -i "/^KUBE_API_ADDRESS=/cKUBE_API_ADDRESS=\"--insecure-bind-address=0.0.0.0\"" /etc/kubernetes/apiserver
sed -i "/^KUBE_ETCD_SERVERS=/cKUBE_ETCD_SERVERS=\"--etcd-servers=http://${prefix}.etcd:2379\"" /etc/kubernetes/apiserver

#若创建pod认证失败，删除ServiceAccount SecurityContextDeny 这2个选项
sed -i "s/SecurityContextDeny,//g" /etc/kubernetes/apiserver
sed -i "s/ServiceAccount,//g" /etc/kubernetes/apiserver


#配置config
sed -i "/^KUBE_MASTER=/cKUBE_MASTER=\"--master=http://${prefix}.master:8080\"" /etc/kubernetes/config

#启动
systemctl enable kube-apiserver kube-scheduler kube-controller-manager
systemctl start kube-apiserver kube-scheduler kube-controller-manager
netstat -nlpt | grep kube

#测试
curl http://${master_ip}:8080/version


#4.node部署完成后验证集群是否成功
kubectl get nodes
exit