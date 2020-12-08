#!/bin/bash
#获取本机ip地址
IP_ADDRESS=$(ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | grep -v 172 | cut -d '/' -f1 | head -1)
echo -e '\033[1;32m 安装GitLab \033[0m'
echo -e '\033[1;32m 1.安装SSH \033[0m'
yum -y install curl policycoreutils openssh-server openssh-clients policycoreutils-python
echo -e '\033[1;32m 设置SSH开机自启动 \033[0m'
systemctl enable sshd
echo -e '\033[1;32m 启动SSH服务 \033[0m'
systemctl start sshd

echo -e '\033[1;32m 2.安装邮件系统用来发送邮件 \033[0m'
yum -y install postfix
systemctl enable postfix
systemctl start postfix

echo -e '\033[1;32m 安装GitLab社区版 \033[0m'
wget -c https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/gitlab-ce-11.4.6-ce.0.el7.x86_64.rpm
rpm -i gitlab-ce-11.4.6-ce.0.el7.x86_64.rpm
echo -e '\033[1;32m 添加定时任务，每天凌晨两点，执行gitlab备份 \033[0m'
sed -i '$a\0  2    * * *   root    /opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1' /etc/crontab
echo -e '\033[1;32m 加载任务,使之生效 \033[0m'
crontab /etc/crontab
echo -e '\033[1;32m 查看任务 \033[0m'
crontab -l
echo -e '\033[1;32m 自动编辑gitlab配置文件，设置域名和文件保存时间，默认保存7天 \033[0m'
sed -i "s/external_url 'http:\/\/gitlab.example.com'/external_url 'http:\/\/${IP_ADDRESS}'/g" /etc/gitlab/gitlab.rb
sed -i "s/# gitlab_rails\['backup_keep_time'\] = 604800/gitlab_rails\['backup_keep_time'\] = 604800/g" /etc/gitlab/gitlab.rb
echo -e '\033[1;32m 更新配置并重启 \033[0m'
gitlab-ctl reconfigure
echo -e '\033[1;32m 查看gitlab服务启动状态 \033[0m'
gitlab-ctl status
echo -e '\033[1;32m 使用以下指令启动|停止|查看状态|重启服务管理gitlab \033[0m'
echo -e '\033[1;33m gitlab-ctl start|stop|status|restart \033[0m'
echo -e '\033[1;32m GitLab配置完成！\033[0m'
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all
exit
