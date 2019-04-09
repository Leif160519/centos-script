#!/bin/bash
# erlang下载 https://www.erlang-solutions.com/resources/download.html
# RabbitMQ下载 https://www.rabbitmq.com/install-rpm.html#install-erlang

centos6=`grep -cIE 'CentOS.*?6.*?' /etc/issue`
centos7=`grep -cIE 'CentOS.*?7.*?' /etc/issue`

if [ $centos6 = 1 -o $centos7 = 1 ]; then
    echo -e "\033[1;31m 1.卸载RabbitMQ \033[0m"
    yum remove rabbitmq
    rpm -qa | grep rabbitmq | xargs -I {} rpm -e {}
    echo -e "\033[1;31m 2.卸载erlang  \033[0m"
    yum remove erlang
    rpm -qa | grep erlang | xargs -I {} rpm -e {}
    echo -e "\033[1;31m 3.安装socat  \033[0m"
    yum -y install socat
fi

if [ $centos6 = 1 ]; then
    echo -e "\033[1;31m 4.下载erlang  \033[0m"
    wget https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_21.1.3-1~centos~6_amd64.rpm
    echo -e "\033[1;31m 5.安装erlang \033[0m"
    rpm -ivh esl-erlang_21.1.3-1~centos~6_amd64.rpm
    echo -e "\033[1;31m 6.下载RabbitMQ \033[0m"
    wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.11/rabbitmq-server-3.7.11-1.el6.noarch.rpm
    echo -e "\033[1;31m 7.安装RabbitMQ  \033[0m"
    rpm -ivh --nodeps rabbitmq-server-3.7.11-1.el6.noarch.rpm
fi

if [ $centos7 = 1 ]; then
    echo -e "\033[1;31m 4.下载erlang \033[0m"
    wget https://www.rabbitmq.com/releases/erlang/erlang-19.0.4-1.el7.centos.x86_64.rpm
    echo -e "\033[1;31m 5.下载RabbitMQ \033[0m"
    wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.6/rabbitmq-server-3.6.6-1.el7.noarch.rpm
    echo -e "\033[1;31m 6.安装支持的环境 \033[0m"
    rpm -ivh erlang-19.0.4-1.el7.centos.x86_64.rpm
    echo -e "\033[1;31m 7.安装RabbitMQ \033[0m"
    rpm -ivh rabbitmq-server-3.6.6-1.el7.noarch.rpm
fi

echo -e "\033[1;31m 8.设置开机启动 \033[0m"
service enable rabbitmq-server
echo -e "\033[1;31m 9.编辑配置 \033[0m"
cat <<EOF >/etc/rabbitmq/rabbitmq.config
[{rabbit,[{loopback_users, []}]}] .
EOF
echo -e "\033[1;31m 10.启动服务 \033[0m"
service rabbitmq-server restart
echo -e "\033[1;31m 11.查看服务状态 \033[0m"
service rabbitmq-server status
echo -e "\033[1;31m 12.开启管理功能 \033[0m"
rabbitmq-plugins enable rabbitmq_management
echo -e "\033[1;31m 13.重启服务 \033[0m"
service rabbitmq-server restart
echo -e "\033[1;31m 14.增加管理员用户 \033[0m"
rabbitmqctl add_user admin 123456
rabbitmqctl set_user_tags admin administrator
echo -e "\033[1;31m 15.在浏览器中使用端口15672登录控制台，可以对RabbitMQ进行管理 \033[0m"
curl http://localhost:15672
echo -e '\033[1;32m RabbitMQ配置完成！\033[0m'
exit   
