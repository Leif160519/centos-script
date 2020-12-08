#!/bin/bash
if [[ -f /etc/redhat-release ]];then
    centos_major_version=$(awk '{print $4}' /etc/redhat-release | awk -F. '{print $1}')
    # 下载源配置文件
    wget -c http://mirrors.aliyun.com/repo/Centos-"${centos_major_version}".repo -O /etc/yum.repos.d/CentOS-Base.repo
    #更新
    yum makecache
    yum -y update
else
    echo "非centos或redhat系统"
    exit 1;
fi
