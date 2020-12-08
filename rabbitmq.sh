#!/bin/bash
# erlang下载 https://www.erlang-solutions.com/resources/download.html;https://github.com/rabbitmq/erlang-rpm/releases

# RabbitMQ下载 https://www.rabbitmq.com/install-rpm.html#install-erlang;https://github.com/rabbitmq/rabbitmq-server/releases/

centos6=$(grep -cIE 'CentOS.*?6.*?' /etc/issue)
centos7=$(grep -cIE 'CentOS.*?7.*?' /etc/issue)

if [ "$centos6" == 1 -o "$centos7" == 1 ]; then
    echo -e "\033[1;32m 1.卸载RabbitMQ \033[0m"
    yum -y remove rabbitmq
    rpm -qa | grep rabbitmq | xargs -I {} rpm -e {}
    echo -e "\033[1;32m 2.卸载erlang  \033[0m"
    yum -y remove erlang
    rpm -qa | grep erlang | xargs -I {} rpm -e {}
    echo -e "\033[1;32m 3.安装socat  \033[0m"
    yum -y install socat
fi

if [ "$centos6" == 1 ]; then
    echo -e "\033[1;32m 4.下载erlang  \033[0m"
    wget -c https://github.com/rabbitmq/erlang-rpm/releases/download/v21.3.8.1/erlang-21.3.8.1-1.el6.x86_64.rpm
    echo -e "\033[1;32m 5.安装erlang \033[0m"
    rpm -ivh erlang-21.3.8.1-1.el6.x86_64.rpm
    echo -e "\033[1;32m 6.下载RabbitMQ \033[0m"
    wget -c https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.el6.noarch.rpm
    echo -e "\033[1;32m 7.安装RabbitMQ  \033[0m"
    rpm -ivh rabbitmq-server-3.7.14-1.el6.noarch.rpm
fi

if [ "$centos7" == 1 ]; then
    echo -e "\033[1;32m 4.下载erlang \033[0m"
    wget -c https://github.com/rabbitmq/erlang-rpm/releases/download/v21.3.8.1/erlang-21.3.8.1-1.el7.x86_64.rpm
    echo -e "\033[1;32m 5.安装erlang \033[0m"
    rpm -ivh erlang-21.3.8.1-1.el7.x86_64.rpm
    echo -e "\033[1;32m 6.下载RabbitMQ \033[0m"
    wget -c https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.el7.noarch.rpm
    echo -e "\033[1;32m 7.安装RabbitMQ \033[0m"
    rpm -ivh rabbitmq-server-3.7.14-1.el7.noarch.rpm
fi

echo -e "\033[1;32m 8.设置开机启动 \033[0m"
systemctl enable rabbitmq-server
echo -e "\033[1;32m 9.编辑配置 \033[0m"
cat <<EOF >/etc/rabbitmq/rabbitmq.config
[{rabbit,[{loopback_users, []}]}] .
EOF
cat <<EOF >/etc/rabbitmq/rabbitmq-env.conf
NODENAME=rabbit@localhost
EOF
#重新启动服务
echo -e "\033[1;32m 10.启动服务 \033[0m"
systemctl restart  rabbitmq-server
echo -e "\033[1;32m 11.开启管理功能 \033[0m"
rabbitmq-plugins enable rabbitmq_management
echo -e "\033[1;32m 12.重启服务 \033[0m"
systemctl restart  rabbitmq-server
echo -e "\033[1;32m 13.增加管理员用户 \033[0m"
rabbitmqctl add_user admin 123456
rabbitmqctl set_user_tags admin administrator
echo -e "\033[1;32m 14.在浏览器中使用端口15672登录控制台，可以对RabbitMQ进行管理 \033[0m"
curl http://localhost:15672
echo -e '\033[1;32m RabbitMQ配置完成！\033[0m'
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all
exit
