# 注意事项
## 1. 此脚本适用于Centos 7(最小化安装，无图形界面)，部分脚本内容包含Ubuntu下的用法，可根据实际情况进行变更
## 2. 脚本中涉及的IP地址和路径可以根据实际情况进行更改，但是有些路径是固定的，更改过后会出现问题，故在运行之前先了解一下工作原理
## 3. 脚本在运行过程中自带彩色字体输出，某些脚本执行一定流程过后需要手动操作，并非无人值守，请执行前先看一下执行步骤，涉及手动操作和其他命令的提示用黄色表示，密码提示等用红色表示

# 文件介绍
## 1. Base.sh
centos 基础环境配置，安装必备组件和一些运维组件：

| 序号 | 软件名称 | 说明 | 使用方法 |
| --- | --- | --- | --- |
| 1 | wget | wget命令用来从指定的URL下载文件 | https://man.linuxde.net/wget |
| 2 | nano | nano是一个字符终端的文本编辑器，有点像DOS下的editor程序 | https://man.linuxde.net/nano |
| 3 | zip | zip命令可以用来解压缩文件，或者对文件进行打包操作 | https://man.linuxde.net/zip |
| 4 | unzip | unzip命令用于解压缩由zip命令压缩的“.zip”压缩包 | https://man.linuxde.net/unzip |
| 5 | git | Linux git命令是文字模式下的文件管理员 | https://man.linuxde.net/git |
| 6 | java | 不解释 |  |
| 7 | yum-utils | yum工具包 |  |
| 8 | expect | Expect是Unix系统中用来进行自动化控制和测试的软件工具 | https://man.linuxde.net/expect-%e7%99%be%e7%a7%91%e7%af%87 |
| 9 | htop |  |  |
| 10 | iotop | iotop命令是一个用来监视磁盘I/O使用状况的top类工具 | https://man.linuxde.net/iotop |
| 11 | iftop |  |  |
| 12 | nethogs |  | https://man.linuxde.net/nethogs |
| 13 | mrtg |  |  |
| 14 | nagios | NetHogs是一个开源的命令行工具（类似于Linux的top命令），用来按进程或程序实时统计网络带宽使用率 | https://man.linuxde.net/nethogs |
| 15 | cacti |  |  |
| 16 | npm |  |  |
| 17 | pv |  |  |
| 18 | telnet | telnet命令用于登录远程主机，对远程主机进行管理 | https://man.linuxde.net/telnet |
| 19 | net-tools | centos网络工具包 |  |
| 20 | tree | tree命令以树状图列出目录的内容 | https://man.linuxde.net/tree |
| 21 | tmux |  |  |
| 22 | iperf | iperf命令是一个网络性能测试工具 | https://man.linuxde.net/iperf |
| 23 | figlet |  |  |
| 24 | lsof | lsof命令用于查看你进程开打的文件，打开文件的进程，进程打开的端口(TCP、UDP) | https://man.linuxde.net/lsof |
| 25 | dpkg | dpkg命令是Debian Linux系统用来安装、创建和管理软件包的实用工具 | https://man.linuxde.net/dpkg |
| 26 | hdparm | hdparm命令提供了一个命令行的接口用于读取和设置IDE或SCSI硬盘参数 | https://man.linuxde.net/hdparm |
| 27 | smartmontools |  |  |
| 28 | psmisc |  |  |
| 29 | fping |  |  |
| 30 | tcpdump | tcpdump命令是一款sniffer工具，它可以打印所有经过网络接口的数据包的头信息，也可以使用-w选项将数据包保存到文件中，方便以后分析 | https://man.linuxde.net/tcpdump |
| 31 | nmap | nmap命令是一款开放源代码的网络探测和安全审核工具，它的设计目标是快速地扫描大型网络 | https://man.linuxde.net/nmap |
| 32 | fio |  |  |
| 33 | nc | nc命令是netcat命令的简称，都是用来设置路由器 | https://man.linuxde.net/nc_netcat |
| 34 | strace | strace命令是一个集诊断、调试、统计与一体的工具 | https://man.linuxde.net/strace |
| 35 | perf |  |  |
| 36 | iostat | iostat命令被用于监视系统输入输出设备和CPU的使用情况 | https://man.linuxde.net/iostat |
| 37 | dig | dig命令是常用的域名查询工具，可以用来测试域名系统工作是否正常 | https://man.linuxde.net/dig / https://man.linuxde.net/dig-2 |
| 38 | dstat | dstat命令是一个用来替换vmstat、iostat、netstat、nfsstat和ifstat这些命令的工具 | https://man.linuxde.net/dstat |


其他软件及操作
|  序号 |  软件/操作名称 |  作用 |
| --- | --- | --- |
| 1 | 安装时间同步服务器 | 与网络时间同步 |
| 2 | 关闭swap分区 |  |
| 3 | 关闭防火墙 |  |
| 4 | screenfetch | 查看系统信息 |
| 5 | neofetch | 查看系统信息 |
| 6 | 关闭SSH DNS反向解析和GSSAPI的用户认证  | 防止ssh超时掉线 |


## 2. Docker&docker-compose
安装 *`Docker`* 和 *`docker-compose`*

## 3. Gitlab.sh
安装 *`Gitlab`* ，支持中文(登录过后在setting中设置语言即可)，设置包括：

1.安装 *`SSH `* ----------------------------------------------------(一般Linux都自带，支持SSH克隆或者提交代码)，

2.安装 *`邮件服务器`* ----------------------------------------------------(git注册和找回密码合并代码等发送邮件用)，

3.安装 *`Gitlab 社区版`*

4.设置 *`定时任务，每天凌晨两点，执行gitlab备份`* 

5.设置 *`gitlab域名`* --------------------------------------------------------------------------(形成正确的仓库连接)，

6.设置 *`备份保存时间，默认7天`* 

> 备份时间和备份保存时间可根据实际情况修改

> 查看gitlab版本号`cat /opt/gitlab/embedded/service/gitlab-rails/VERSION`

gitlab相关资料：

- [Gitlab如何进行备份恢复与迁移？](https://leif.fun/articles/2019/08/29/1567060138639.html)

- [完全卸载GitLab](https://leif.fun/articles/2019/08/29/1567058106789.html)

- [centos搭建gitlab社区版](https://leif.fun/articles/2019/08/29/1567057627672.html)

- [解决Gitlab迁移服务器后SSH key无效的问题](https://leif.fun/articles/2019/08/22/1566472573139.html)

## 4. MongoDB.sh
安装 *`MongoDB`* 数据库

- *`MongoDB`* 默认没有用户名和密码，可以用Navicat等数据库管理工具直接连接

mongodb相关资料：

- [MongoDB 备份(mongodump)与恢复(mongorestore)](https://leif.fun/articles/2019/08/30/1567127999119.html)

- [开启mongodb远程访问](https://leif.fun/articles/2019/08/30/1567127345260.html)

- [mongodb服务启动失败](https://leif.fun/articles/2019/08/30/1567127175232.html)

- [升级 MongoDB 到 4.0](https://leif.fun/articles/2019/08/30/1567127101249.html)

## 5. MySQL.sh
安装 *`MySQL`* 数据库社区版，脚本主要设置了固定密码。

关于如何开启远程访问(centos 7下)：

1.登录进mysql
```
mysql -u root -p
```
2.更新表内容
```
grant all privileges on *.* to 'root' @'%' identified by '你的root用户密码’;
```
3.刷新权限
```
flush privileges;
```

> [mysql相关内容](https://leif.fun/search?keyword=mysql)

附：[mysql5.7安装包(rpm)](https://centos.pkgs.org/7/mysql-5.7-x86_64/)

## 6.python3.7.sh
编译安装 *`Python3.7`*

安装pip并升级到最新版
> [python相关内容](https://leif.fun/search?keyword=python)


## 7. RabbitMQ.sh
安装 *`RabbitMQ`* 消息通知

>访问端口号 *`16572`* ， 用户名 *`admin`*  ，密码 *`123456`* 

erlang下载(github): https://github.com/rabbitmq/erlang-rpm/releases

| 描述 | 下载 |
| --- | --- |
| 适用于运行RabbitMQ的CentOS 7的零依赖Erlang / OTP 21.3.8.1软件包 | [erlang-21.3.8.1-1.el7.x86_64.rpm](https://github.com/rabbitmq/erlang-rpm/releases/download/v21.3.8.1/erlang-21.3.8.1-1.el7.x86_64.rpm) |
| 适用于运行RabbitMQ的CentOS 6的零依赖Erlang / OTP 21.3.8.1软件包 | [erlang-21.3.8.1-1.el6.x86_64.rpm](https://github.com/rabbitmq/erlang-rpm/releases/download/v21.3.8.1/erlang-21.3.8.1-1.el6.x86_64.rpm) |

>截止2019年05月16日，rabbitmq官网暂未更新erlang 21.3.8.1版本

RabbitMQ下载(github): https://github.com/rabbitmq/rabbitmq-server/releases/

| 描述 | 下载 |
| --- | --- |
| 适用于RHEL Linux 7.x，CentOS 7.x，Fedora 19+的RPM（支持systemd） | [rabbitmq-server-3.7.14-1.el7.noarch.rpm](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.el7.noarch.rpm) |
| 适用于RHEL Linux 6.x，CentOS 6.x，Fedora之前的RPM | [rabbitmq-server-3.7.14-1.el6.noarch.rpm](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.el6.noarch.rpm) |
| openSUSE Linux的RPM | [rabbitmq-server-3.7.14-1.suse.noarch.rpm](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.suse.noarch.rpm) |
| SLES 11.x的RPM|[rabbitmq-server-3.7.14-1.sles11.noarch.rpm](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.sles11.noarch.rpm)|

>截止2019年05月16日，rabbitmq官网暂未更新rabbitmq 3.7.14版本


## 8. Supervisor.sh
安装 *`supervisor`* 进程管理工具设置应用程序开机自启动

- 上述 *`Base.sh`* 设置了 *`supervisor`* 的管理界面，端口号 *`9001`* ，用户名 *`admin`* ，密码 *`123456`* 

- 具体安装教程：[centos7安装supervisor](https://leif.fun/articles/2019/08/28/1566986488665.html)

## 9.monitor
监控软件
### 9.1 netdata.sh
Linux硬件资源监控软件，默认访问端口`1999`
![image.png](https://img.hacpai.com/file/2019/09/image-90b66926.png)
> 部署教程参考:[netdata监控搭建及使用](https://leif.fun/articles/2019/09/10/1568097487995.html)

### 9.2 goaccess.sh
分析nginx日志的工具，默认访问端口`7890`
![image.png](https://img.hacpai.com/file/2019/09/image-da5afe19.png)
> 部署教程参考:[(超级详细)使用GoAccess分析Nginx日志的安装和配置](https://leif.fun/articles/2019/09/10/1568098665037.html)

### 9.3 cockpit.sh
轻量级硬件资源监控软件，默认访问端口`9090`，用户名为Linux用户名，密码为Linux登录密码
![image.png](https://img.hacpai.com/file/2019/09/image-158bc1f9.png)

![image.png](https://img.hacpai.com/file/2019/09/image-e46a3ece.png)

## 10. k8s.sh
centos下k8s安装脚本

k8s相关资料：

- [Kubernetes相关资料](https://leif.fun/articles/2019/09/06/1567758755140.html)

- [Kubernetes 部署失败的 10 个最普遍原因（Part 1）](https://leif.fun/articles/2019/09/06/1567758470060.html)

- [CentOS7.5 Kubernetes V1.13 二进制部署集群](https://leif.fun/articles/2019/09/06/1567755955285.html)

- [《每天5分钟玩转Kubernetes》读书笔记](https://leif.fun/articles/2019/09/18/1568772630383.html)

## 11.oh-my-zsh.sh
安装zsh配置oh-my-zsh

## 12.rar.sh
安装rar解压缩命令

## 13.node.sh
安装node和npm

## 14. LDAP.sh
LDAP是Lightweight Directory Access Protocol ， 即轻量级目录访问协议， 用这个协议可以访问提供目录服务的产品

参考资料：

- Centos7 搭建openldap完整详细教程(真实可用)：https://blog.csdn.net/weixin_41004350/article/details/89521170

- OpenLDAP管理工具之LDAP Admin：https://cloud.tencent.com/developer/article/1380076

- Gitlab使用LDAP用户管理配置：https://blog.csdn.net/qq_40140473/article/details/96312452

- gitlab详细配置ldap：https://blog.csdn.net/len9596/article/details/81222764

## 15. zabbix
安装zabbix服务，使用`zabbix-linux.sh`前提需要安装`mysql`(mysql不能装在docker中，否则zabbix-server不可用)。
个人推荐`zabbix-docker.sh`，比较方便。
![image.png](https://img.hacpai.com/file/2020/04/image-ca7b3026.png)

![image.png](https://img.hacpai.com/file/2020/04/image-9952a2b4.png)

![image.png](https://img.hacpai.com/file/2020/04/image-0a2643d4.png)

参考资料：

- [【Zabbix】CentOS7.3下使用Docker安装Zabbix](https://www.jianshu.com/p/b2d44c733c2d)

- [Linux老司机带你学Zabbix从入门到精通（一）](https://zhuanlan.zhihu.com/p/35064593)

- [Linux老司机带你学Zabbix从入门到精通（二）](https://zhuanlan.zhihu.com/p/35068409)

- [基于 docker 部署 zabbix 及客户端批量部署](https://blog.rj-bai.com/post/144.html)

# 用法
很多工具的安装依赖 *`Base.sh`* 中涉及到的工具，故建议先执行Base.sh，再根据实际需求执行上述其他脚本

祝好运！