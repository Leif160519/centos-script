#!/bin/bash
echo -n -e "\033[1;32m 请输入zabbix服务器地址： \033[0m"
read zabbix_server_ip
rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm

function install_agent(){
  if [[ `yum list installed | grep zabbix-agent |wc -l` == 0 ]];then
    yum -y clean all
    yum -y install zabbix-agent
    install_agent
  else
    echo -e '\033[1;32m zabbix-agent已经安装 \033[0m'
  fi
}

install_agent


echo -e "\033[1;32m 安装zabbix-sender工具\033[0m"
function install_zabbix_sender(){
  if [[ `yum list installed | grep zabbix-sender |wc -l` == 0 ]];then
    yum install -y zabbix-sender
    install_zabbix_sender
  else
    echo -e '\033[1;32m zabbix-sender已经安装 \033[0m'
  fi
}

install_zabbix_sender


echo -e "\033[1;32m 修改zabbix-agent配置文件 \033[0m"
sed -i "s/Server=127.0.0.1/Server=${zabbix_server_ip}/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/ServerActive=${zabbix_server_ip}/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/# UnsafeUserParameters=0/UnsafeUserParameters=1/g" /etc/zabbix/zabbix_agentd.conf

#此命令只能在zabbix-server端执行，不能在zabbix-agent端执行，否则zabbix-agent服务无法启动
#sed -i "s/# AllowRoot=0/AllowRoot=1/g" /etc/zabbix/zabbix_agentd.conf

echo -e "\033[1;32m 启动zabbix-agent服务 \033[0m"
systemctl start zabbix-agent
systemctl enable zabbix-agent
systemctl status zabbix-agent

yum -y clean all
exit