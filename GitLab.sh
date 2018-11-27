#!/bin/bash
echo -e '\033[1;31m ********************************此脚本自动化安装GitLab******************************** \033[0m'
echo -e '\033[1;31m 1.安装SSH \033[0m'
yum -y install curl policycoreutils openssh-server openssh-clients
echo -e '\033[1;31m 设置SSH开机自启动 \033[0m'
systemctl enable sshd
echo -e '\033[1;31m 启动SSH服务 \033[0m'
systemctl start sshd
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 2.安装邮件系统用来发送邮件 \033[0m'
yum -y install postfix
systemctl enable postfix
systemctl start postfix
echo -e '\033[1;31m ********************************************************************************** \033[0m'

echo -e '\033[1;31m 安装GitLab社区版 \033[0m'
curl -sS http://packages.gitlab.cc/install/gitlab-ce/script.rpm.sh | sudo bash
# ubuntu下：curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
yum -y install gitlab-ce
echo -e '\033[1;31m 添加定时任务，每天凌晨两点，执行gitlab备份 \033[0m'
cat <<EOF > /etc/crontab
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root

# For details see man 4 crontabs

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name  command to be executed
# 添加定时任务，每天凌晨两点，执行gitlab备份
0  2    * * *   root    /opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1
EOF

# ubuntu下：
# cat <<EOF > /etc/crontab
# # /etc/crontab: system-wide crontab
# # Unlike any other crontab you don't have to run the `crontab'
# # command to install the new version when you edit this file
# # and files in /etc/cron.d. These files also have username fields,
# # that none of the other crontabs do.

# SHELL=/bin/sh
# PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# # m h dom mon dow user	command
# 17 *	* * *	root    cd / && run-parts --report /etc/cron.hourly
# 25 6	* * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
# 47 6	* * 7	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
# 52 6	1 * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )
# #
# # edited by ouyang 2017-8-11 添加定时任务，每天凌晨两点，执行gitlab备份
# 0  2    * * *   root    /opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1
# EOF

echo -e '\033[1;31m 自动编辑gitlab配置文件，设置域名和文件保存时间，默认保存7天 \033[0m'
cat <<EOF > /etc/gitlab/gitlab.rb
## GitLab configuration settings

## GitLab URL
external_url 'http://192.168.3.233'

### Backup Settings

# gitlab_rails['manage_backup_path'] = true
# gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"

# gitlab_rails['backup_archive_permissions'] = 0644

# gitlab_rails['backup_pg_schema'] = 'public'

# 修改备份文件保存时间为7天
gitlab_rails['backup_keep_time'] = 604800
EOF
echo -e '\033[1;31m 更新配置并重启 \033[0m'
gitlab-ctl reconfigure
echo -e '\033[1;31m 查看gitlab服务启动状态 \033[0m'
gitlab-ctl status
echo -e '\033[1;31m 使用以下指令启动|停止|查看状态|重启服务管理gitlab \033[0m'
echo -e '\033[1;33m gitlab-ctl start|stop|status|restart \033[0m'
echo -e '\033[1;32m GitLab配置完成！\033[0m'
exit