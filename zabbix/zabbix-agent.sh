#!/bin/bash
echo -n "请输入zabbix服务器地址："
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




echo "修改zabbix-agent配置文件"
sed -i "s/Server=127.0.0.1/Server=${zabbix_server_ip}/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/# UnsafeUserParameters=0/UnsafeUserParameters=1/g" /etc/zabbix/zabbix_agentd.conf

echo "启动zabbix-agent服务"
systemctl start zabbix-agent
systemctl enable zabbix-agent
systemctl status zabbix-agent

yum -y clean all
exit