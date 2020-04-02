# 注意事项
## 1. 此脚本适用于Centos 7(最小化安装，无图形界面)，部分脚本内容包含Ubuntu下的用法，可根据实际情况进行变更
## 2. 脚本中涉及的IP地址和路径可以根据实际情况进行更改，但是有些路径是固定的，更改过后会出现问题，故在运行之前先了解一下工作原理
## 3. 脚本在运行过程中自带彩色字体输出，某些脚本执行一定流程过后需要手动操作，并非无人值守，请执行前先看一下执行步骤，涉及手动操作和其他命令的提示用黄色表示，密码提示等用红色表示

# 文件介绍
## 1. Base.sh
centos 基础环境配置，安装配置必备组件，包括(按照脚本执行顺序介绍)：

1.安装 *`wget`* -------------------------------------------------------------------(后面很多工具要通过wget下载)，

2.更换 *`阿里源`* ----------------------------------------------------------------------------------(更快的下载速度)，

3.安装 *`nano`* ----------------------------------------------------------------(文件编辑器，喜欢vim的可以不装)， 

4.安装 *`zip`* --------------------------------------------------------------------------------------(zip压缩工具)，

5.安装 *`unzip`* --------------------------------------------------------------------------------------(zip解压工具)， 

6.安装 *`git`* ----------------------------------------------------------------------------------(代码版本控制工具)， 

7.安装 *`java`* --------------------------------------------------------------------------------------(程序员都懂得)， 

8.安装 *`yum-utils`* -------------------------------------------------------------------------------(yum工具支持)， 

9.安装 *`expect`* ----------------------------------------------------------------------(一个用来处理交互的命令)，

10.安装 *`htop`* --------------------------------------------------------------------(非常好用的系统资源监测工具)， 

11.安装 *`iotop`* --------------------------------------------------------------------(监控磁盘IO)，

12.安装 *`iftop`* --------------------------------------------------------------------(监控主机间流量  -i 指定监控网卡)，

13.安装 *`nethogs`* --------------------------------------------------------------------(监控进程流量)，

14.安装 *`mrtg`* --------------------------------------------------------------------(流量监控出图)，

15.安装 *`nagios`* --------------------------------------------------------------------(监控)，

16.安装 *`cacti`* --------------------------------------------------------------------(流量监控出图)，

17.安装 *`npm`* -------------------------------------------------------------------------------------(node包管理器)，

18.安装 *`pv`* --------------------------------------------------------------------------------(复制文件显示进度条)， 

19.安装 *`telnet`* ---------------------------------------------------------------------------------------(网络工具)，

20.安装 *`net-tools`* -------------------------------------------------------------(支持ifconfig、netstat命令等)，

21.安装 *`tree`* -----------------------------------------------------------------------------(显示文件夹树形结构)，

22.安装 *`时间同步服务器`* -----------------------------------------------------------(时间不同步连交流都很麻烦)，

23.关闭 *`swap分区`* 、

24.关闭并禁用 *`系统防火墙`* 、

25.关闭 *`SSH DNS反向解析和GSSAPI的用户认证`* --------------------------------------------(提升SSH连接速度)，

206.安装 *`screenfetch`* ---------------------------------------------------------(控制台打印计算机软硬件信息)，

27.安装 *`tmux`* -------------------------------------------------------------------------(一个非常好用的终端工具)，

28.安装 *`iperf`* -------------------------------------------------------------------(网络工具，可以测试内网网速),

29.安装 *`figlet`* -----------------------------------------------(命令生成字符画，只支持英文,数字和部分符号),

30.安装 *`lsof`* ---------------------------------------------------------------------(可以显示端口被哪些进程占用),

31.安装 *`dpkg`* -------------------------------------------------------------------------------------(安装deb安装包),

32.安装 *`hdparm`* -------------------------------------------------------------------------------(测试硬盘读写速率),

33.安装 *`smartmontools`* ---------------------------------------------------------------------(测试硬盘健康状态),

34.安装 *`psmisc`* -----------------------------------------------------------------------------(killall命令),

35.安装 *`fping`* --------------------------------------------------------------------------(检测某个IP是否活跃)。

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
安装zabbix服务，`zabbix-linux.sh`前提需要安装`docker`和`docker-compose`，脚本会自动生成mysql的容器，无需另外手动安装和配置mysql。
个人推荐`zabbix-docker.sh`，比较方便。
![image.png](https://img.hacpai.com/file/2020/04/image-5869b6c6.png)

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