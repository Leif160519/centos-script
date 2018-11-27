#!/bin/bash
echo -e '\033[1;31m ********************************此脚本自动化安装RabbitMQ******************************** \033[0m'
echo -e "\033[1;31m 1.下载erlang \033[0m"
wget https://www.rabbitmq.com/releases/erlang/erlang-19.0.4-1.el7.centos.x86_64.rpm
echo -e "\033[1;31m 2.下载RabbitMQ \033[0m"
wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.6/rabbitmq-server-3.6.6-1.el7.noarch.rpm
echo -e "\033[1;31m 3.安装支持的环境 \033[0m"
rpm -ivh erlang-19.0.4-1.el7.centos.x86_64.rpm
echo -e "\033[1;31m 4.安装RabbitMQ \033[0m"
yum -y install socat
rpm -ivh rabbitmq-server-3.6.6-1.el7.noarch.rpm
echo -e "\033[1;31m 5.设置开机启动 \033[0m"
systemctl enable rabbitmq-server
echo -e "\033[1;31m 6.编辑配置 \033[0m"
cat <<EOF >/etc/rabbitmq/rabbitmq.config
[{rabbit,[{loopback_users, []}]}] .
EOF
echo -e "\033[1;31m 7.启动服务 \033[0m"
service rabbitmq-server restart
echo -e "\033[1;31m 8.查看服务状态 \033[0m"
service rabbitmq-server status
echo -e "\033[1;31m 9.开启管理功能 \033[0m"
rabbitmq-plugins enable rabbitmq_management
echo -e "\033[1;31m 10.重启服务 \033[0m"
service rabbitmq-server restart
echo -e "\033[1;31m 11.增加管理员用户 \033[0m"
rabbitmqctl add_user admin 123456
rabbitmqctl set_user_tags admin administrator
echo -e "\033[1;31m 12.在浏览器中使用端口15672登录控制台，可以对RabbitMQ进行管理 \033[0m"
curl http://localhost:15672
echo -e '\033[1;32m RabbitMQ配置完成！\033[0m'
exit
