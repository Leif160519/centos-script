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
${prefix}.node1
EOF

#3.master部署过后部署node
#安装docker 
yum -y install docker
#开机自启 并启动
systemctl enable docker  && systemctl start docker
ip a s docker0
cat <<EOF >/etc/docker/daemon.json
{"registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]}
EOF
#重启
systemctl restart docker
#查看仓库源是否设置成功
docker info


#部署flannel
#安装
yum -y install flannel
#修改配置
sed -i "/^FLANNEL_ETCD_ENDPOINTS=/cFLANNEL_ETCD_ENDPOINTS=\"http://${prefix}.etcd:2379\"" /etc/sysconfig/flanneld
sed -i "/^FLANNEL_ETCD_PREFIX=/cFLANNEL_ETCD_PREFIX=\"/atomic.io/network\"" /etc/sysconfig/flanneld
#开机自启并启动服务
systemctl enable flanneld && systemctl restart flanneld
netstat -nlp | grep flanneld

#安装服务
yum -y install kubernetes-node
#修改配置
sed -i "/^KUBE_MASTER=/cKUBE_MASTER=\"--master=http://${prefix}.master:8080\""/etc/kubernetes/config

sed -i "/^KUBELET_HOSTNAME=/cKUBELET_HOSTNAME=\"--hostname-override=${prefix}.node1\"" /etc/kubernetes/kubelet
sed -i "/^KUBELET_API_SERVER=/cKUBELET_API_SERVER=\"--api-servers=http://${prefix}.master:8080\"" /etc/kubernetes/kubelet
#启动服务
systemctl enable kubelet kube-proxy  && systemctl start kubelet kube-proxy
netstat -ntlp | grep kube

#处理潜在bug：创建pod 节点若出现/etc/docker/certs.d/registry.access.redhat.com/redhat-ca.crt: no such file or directory
yum install *rhsm* -y
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm
rpm2cpio python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm | cpio -iv --to-stdout ./etc/rhsm/ca/redhat-uep.pem | tee /etc/rhsm/ca/redhat-uep.pem
docker pull registry.access.redhat.com/rhel7/pod-infrastructure:latest
exit