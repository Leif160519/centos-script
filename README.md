该项目后期将逐步减缓直至停止更新，脚本部署方式逐渐改为`ansible-playbook`的方式，新的项目地址：[ansible-linux][1]

# 一、注意事项
## 1. 此脚本适用于Centos 7，部分脚本内容包含Ubuntu下的用法，可根据实际情况进行变更
## 2. 脚本中涉及的IP地址和路径可以根据实际情况进行更改，但是有些路径是固定的，更改过后会出现问题，故在运行之前先了解一下工作原理
## 3. 部分脚本在运行过程中自带彩色字体输出，某些脚本执行一定流程过后需要手动操作，并非无人值守，请执行前先看一下执行步骤，涉及手动操作和其他命令的提示用黄色表示，密码提示等用红色表示
## 4.部分脚本已经与ansible-linux中的playbook保持逻辑一致。

# 二、文件介绍
## 1. install.sh
centos 基础环境安装，包括常用组件和一些运维工具(以下表格内容不全)：

| 序号 | 软件名称 | 说明 | 使用方法 |
| ---- | -------- | ---- | -------- |
| 1 | epel-release | 为centos或redhat等提供高质量软件包的项目 | |
| 2 | htop | 实时的监控界面 | [htop使用详解--史上最强（没有之一）][2] |
| 3 | iotop | iotop命令是一个用来监视磁盘I/O使用状况的top类工具 | [iotop命令][3] |
| 4 | iftop | 查看实时的网络流量，监控TCP/IP连接等 | [Linux流量监控工具 - iftop (最全面的iftop教程)][4] |
| 5 | nethogs | NetHogs是一个开源的命令行工具（类似于Linux的top命令），用来按进程或程序实时统计网络带宽使用率 | [nethogs命令][5] |
| 6 | cacti | Cacti是一套基于PHP、MySQL、SNMP及RRDTool开发的网络流量监测图形分析工具 | [Linux 监控工具之Cacti使用详解（一）][6] |
| 7 | npm | NPM是随同NodeJS一起安装的包管理工具 | [NPM 使用介绍][7] |
| 8 | pv | 显示当前在命令行执行的命令的进度信息，管道查看器 | [pv][8] |
| 9 | net-tools | 网络工具包 | |
| 10 | tree | tree命令以树状图列出目录的内容 | [tree命令][9] |
| 11 | tmux | tmux是一款优秀的终端复用软件 | [Tmux使用手册][10] / [Tmux 使用教程][11] |
| 12 | iperf | iperf命令是一个网络性能测试工具 | [iperf命令][12] |
| 13 | figlet | 将普通终端文本转换为大字母 | [Figlet 和 Toilet命令用法][13] |
| 14 | lsof | lsof命令用于查看你进程开打的文件，打开文件的进程，进程打开的端口(TCP、UDP) | [lsof命令][14] |
| 15 | smartmontools | 是类Unix系统下实施SMART任务命令行套件或工具 | [Linux 硬盘监控和分析工具：smartctl][15] |
| 16 | fping | Fping程序类似于ping协议回复请求以检测主机是否存在 | [Fping命令解析][16] |
| 17 | nmap | nmap命令是一款开放源代码的网络探测和安全审核工具，它的设计目标是快速地扫描大型网络 | [nmap命令][17] |
| 18 | fio | fio是一个IO测试工具，可以用来测试本地磁盘、网络存储等的性能 | [fio的简单介绍及部分参数翻译][18] |
| 19 | iostat | iostat命令被用于监视系统输入输出设备和CPU的使用情况 | [iostat命令][19] |
| 20 | dstat | dstat命令是一个用来替换vmstat、iostat、netstat、nfsstat和ifstat这些命令的工具 | [dstat命令][20] |
| 21 | lynx | lynx命令是终端上的纯文本模式的网页浏览器，没有JS引擎，不支持CSS排版、图形、音视频等多媒体信息。只能作为一个很有趣的小玩具。| [lynx命令 – 终端上的纯文本浏览器][21] |
| 22 | w3m | w3m是个开放源代码的命令行下面的网页浏览器。| [w3m常用操作][22] |
| 23 | lrzsz | rz：运行该命令会弹出一个文件选择窗口，从本地选择文件上传到服务器(receive)，或从linux服务型下载到windows | |
| 24 | monit | Monit是一款功能非常丰富的进程、文件、目录和设备的监测软件 | [Monit：开源服务器监控工具][23] |
| 25 | ntpdate | ntpdate命令是用来设置本地日期和时间。| [ntpdate命令][24] |
| 26 | vim | vi命令是UNIX操作系统和类UNIX操作系统中最通用的全屏幕纯文本编辑器。 | [vi命令][25] |
| 27 | wget | 用来从指定的URL下载文件 | [wget命令][27] |
| 28 | nano | 是一个字符终端的文本编辑器 | [nano命令][28] |
| 29 | zip | 用来解压缩文件，或者对文件进行打包操作 | [zip命令][29] |
| 30 | unzip | 用于解压缩由zip命令压缩的“.zip”压缩包 | [unzip命令][30] |
| 31 | git | Git 的工作就是创建和保存你项目的快照及与之后的快照进行对比 | [Git 基本操作][31] |
| 32 | yum-utils | yum工具包 |  |
| 33 | expect | Unix系统中用来进行自动化控制和测试的软件工具 | [Expect—百科篇命令][32] |
| 34 | mrtg | 通过SNMP 协议，向运行snmp协议主机询问相关的资料后，主机传递数值给MRTG ，然后MRTG 再绘制成网页上的图表 | [mrtg 简单好用的网络流量监控工具][33] |
| 35 | nagios | 是一款开源的电脑系统和网络监视工具 | [Linux下Nagios的安装与配置][34] |
| 36 | pv | 显示当前在命令行执行的命令的进度信息，管道查看器 | [pv][35] |
| 37 | telnet | 用于登录远程主机，对远程主机进行管理 | [telnet命令][36] |
| 38 | dpkg | 是Debian Linux系统用来安装、创建和管理软件包的实用工具 | [dpkg命令][37] |
| 39 | hdparm | 提供了一个命令行的接口用于读取和设置IDE或SCSI硬盘参数 | [hdparm命令][38] |
| 40 | killall | 使用进程的名称来杀死进程 | [killall命令][39]|
| 41 | tcpdump | 是一款sniffer工具，可以打印所有经过网络接口的数据包的头信息 | [tcpdump命令][40] |
| 42 | nc | nc命令是netcat命令的简称，都是用来设置路由器 | [nc/netcat命令][41] |
| 43 | strace | 一个集诊断、调试、统计与一体的工具 | [strace命令][42] |
| 44 | perf | 性能分析工具 | [在Linux下做性能分析3：perf][43] |
| 45 | dig | 常用的域名查询工具，用来测试域名系统工作是否正常 | [dig命令][44] / [dig命令][45] |
| 46 | nslookup | 常用域名查询工具 | [nslookup命令][46] |


### 1.1 gitlab
安装 *`Gitlab`* ，支持中文(登录过后在setting中设置语言即可)，设置包括：

1.安装 *`SSH `* ----------------------------------------------------(一般Linux都自带，支持SSH克隆或者提交代码)，

2.安装 *`邮件服务器`* ----------------------------------------------------(git注册和找回密码合并代码等发送邮件用)，

3.安装 *`Gitlab 社区版`*

4.设置 *`定时任务，每天凌晨两点，执行gitlab备份`*

5.设置 *`gitlab域名`* --------------------------------------------------------------------------(形成正确的仓库连接)，

6.设置 *`备份保存时间，默认7天`*

> 备份时间和备份保存时间可根据实际情况修改

> 查看gitlab版本号`cat /opt/gitlab/embedded/service/gitlab-rails/VERSION`

> gitlab相关资料：
> - [Gitlab如何进行备份恢复与迁移？][47]
> - [完全卸载GitLab][48]
> - [centos搭建gitlab社区版][49]
> - [解决Gitlab迁移服务器后SSH key无效的问题][50]

### 1.2 mongodb
安装 *`MongoDB`* 数据库

- *`MongoDB`* 默认没有用户名和密码，可以用Navicat等数据库管理工具直接连接

> mongodb相关资料：
> - [MongoDB 备份(mongodump)与恢复(mongorestore)][51]
> - [开启mongodb远程访问][52]
> - [mongodb服务启动失败][53]
> - [升级 MongoDB 到 4.0][54]

### 1.3 mysql
安装mysql压缩版

> [mysql相关内容][55]

附：[mysql5.7安装包(rpm)][56]

### 1.4 rabbitmq
安装 *`RabbitMQ`* 消息通知

> 访问端口号 *`16572`* ， 用户名 *`admin`*  ，密码 *`123456`*

erlang下载:[github][58]

| 描述 | 下载 |
| ---- | ---- |
| 适用于运行RabbitMQ的CentOS 7的零依赖Erlang / OTP 21.3.8.1软件包 | [erlang-21.3.8.1-1.el7.x86_64.rpm][59] |
| 适用于运行RabbitMQ的CentOS 6的零依赖Erlang / OTP 21.3.8.1软件包 | [erlang-21.3.8.1-1.el6.x86_64.rpm][60] |

>截止2019年05月16日，rabbitmq官网暂未更新erlang 21.3.8.1版本

RabbitMQ下载:[github][61]

| 描述 | 下载 |
| ---- | ---- |
| 适用于RHEL Linux 7.x，CentOS 7.x，Fedora 19+的RPM（支持systemd） | [rabbitmq-server-3.7.14-1.el7.noarch.rpm][62] |
| 适用于RHEL Linux 6.x，CentOS 6.x，Fedora之前的RPM | [rabbitmq-server-3.7.14-1.el6.noarch.rpm][63] |
| openSUSE Linux的RPM | [rabbitmq-server-3.7.14-1.suse.noarch.rpm][64] |
| SLES 11.x的RPM|[rabbitmq-server-3.7.14-1.sles11.noarch.rpm][65]|

>截止2019年05月16日，rabbitmq官网暂未更新rabbitmq 3.7.14版本


### 1.5 supervisor
安装 *`supervisor`* 进程管理工具设置应用程序开机自启动

- 上述 *`base.sh`* 设置了 *`supervisor`* 的管理界面，端口号 *`9001`* ，用户名 *`admin`* ，密码 *`123456`*

- 具体安装教程：[centos7安装supervisor][66]

## 2. python3.8.sh
编译安装 `Python3.7`

安装pip并升级到最新版
> [python相关内容][57]

## 3. [monitor](monitor)
监控软件
### 3.1 [netdata][67]
Linux硬件资源监控软件，默认访问端口`1999`
![image.png](images/1.png)
> 部署教程参考:[netdata监控搭建及使用][68]

### 3.2 [goaccess][69]
分析nginx日志的工具，默认访问端口`7890`
![image.png](images/2.png)
> 部署教程参考:[(超级详细)使用GoAccess分析Nginx日志的安装和配置][70]

### 3.3 [cockpit](monitor/cockpit.sh)
轻量级硬件资源监控软件，默认访问端口`9090`，用户名为Linux用户名，密码为Linux登录密码
![image.png](images/3.png)

![image.png](images/4.png)

### 3.4 [Prometheus(p8s)][71]
开源的监控系统，访问端口`9090`，`node_porter`访问端口`9100`

![image.png](images/5.png)

![image.png](images/6.png)


### 3.5 [Grafana][72]
功能强大的监控图形程序，可以接受多个监控平台的数据源。访问端口`3000`,默认用户名：*`admin`，密码：*`admin`。

![image.png](images/7.png)

[Node Exporter Full模板JSON文件][73]

[Dashboard模板仓库][74]

> 参考资料：
> - [Grafana官网][75]
> - [CentOS 7中安装和配置Grafana][76]
> - [对接Grafana][77]

### 3.6. [zabbix][78]
安装zabbix服务，使用`zabbix-linux.sh`前提需要安装`mysql`(mysql不能装在docker中，否则zabbix-server不可用)。
个人推荐`zabbix-docker.sh`，比较方便。
![image.png](images/8.png)

![image.png](images/9.png)

![image.png](images/10.png)

> 参考资料：
> - [【Zabbix】CentOS7.3下使用Docker安装Zabbix][79]
> - [Linux老司机带你学Zabbix从入门到精通（一）][80]
> - [Linux老司机带你学Zabbix从入门到精通（二）][81]
> - [基于 docker 部署 zabbix 及客户端批量部署][82]

## 4. [k8s](k8s)
centos下k8s安装脚本

> k8s相关资料：
> - [Kubernetes相关资料][83]
> - [Kubernetes 部署失败的 10 个最普遍原因（Part 1）][84]
> - [CentOS7.5 Kubernetes V1.13 二进制部署集群][85]
> - [《每天5分钟玩转Kubernetes》读书笔记][86]

## 5. ldap.sh
LDAP是Lightweight Directory Access Protocol ， 即轻量级目录访问协议， 用这个协议可以访问提供目录服务的产品

> 参考资料：
> - [Centos7 搭建openldap完整详细教程(真实可用)][87]
> - [OpenLDAP管理工具之LDAP Admin][88]
> - [Gitlab使用LDAP用户管理配置][89]
> - [gitlab详细配置ldap][90]

## 6. [scl使用指南](scl使用指南/scl使用指南.md)

## 7. nfs.sh
安装网络文件系统（Network File System）NFS

## 8. samba.sh
安装服务信息块（Server Messages Block）文件共享软件samba

## 9. config.sh
系统配置

`./config.sh help`查看详情

> 补充：[Linux 常用命令集合][26]

Good Luck！


[1]:  https://github.com/Leif160519/ansible-linux
[2]:  https://cloud.tencent.com/developer/article/1115041
[3]:  https://man.linuxde.net/iotop
[4]:  https://www.vpser.net/manage/iftop.html
[5]:  https://man.linuxde.net/nethogs
[6]:  https://blog.51cto.com/freeloda/1308140
[7]:  https://www.runoob.com/nodejs/nodejs-npm.html
[8]:  https://wangchujiang.com/linux-command/c/pv.html
[9]:  https://man.linuxde.net/tree
[10]: http://louiszhai.github.io/2017/09/30/tmux/
[11]: https://www.ruanyifeng.com/blog/2019/10/tmux.html
[12]: https://man.linuxde.net/iperf
[13]: https://www.linuxprobe.com/figlet-toilet-command.html
[14]: https://man.linuxde.net/lsof
[15]: https://github.icu/articles/2019/08/22/1566473324516.html
[16]: https://blog.csdn.net/wz_cow/article/details/80967255
[17]: https://man.linuxde.net/nmap
[18]: https://blog.csdn.net/MrSate/article/details/53292102
[19]: https://man.linuxde.net/iostat
[20]: https://man.linuxde.net/dstat
[21]: https://www.linuxcool.com/lynx
[22]: http://blog.lujun9972.win/blog/2016/12/11/w3m%E5%B8%B8%E7%94%A8%E6%93%8D%E4%BD%9C/index.html
[23]: https://www.cnblogs.com/52fhy/p/6412547.html
[24]: https://man.linuxde.net/ntpdate
[25]: https://man.linuxde.net/vi
[26]: https://www.runoob.com/w3cnote/linux-common-command.html
[27]: https://man.linuxde.net/wget
[28]: https://man.linuxde.net/nano
[29]: https://man.linuxde.net/zip
[30]: https://man.linuxde.net/unzip
[31]: https://www.runoob.com/git/git-basic-operations.html
[32]: https://man.linuxde.net/expect-%e7%99%be%e7%a7%91%e7%af%87
[33]: https://blog.51cto.com/dngood/762802
[34]: https://www.cnblogs.com/mchina/archive/2013/02/20/2883404.html
[35]: https://wangchujiang.com/linux-command/c/pv.html
[36]: https://man.linuxde.net/telnet
[37]: https://man.linuxde.net/dpkg
[38]: https://man.linuxde.net/hdparm
[39]: https://man.linuxde.net/killall
[40]: https://man.linuxde.net/tcpdump
[41]: https://man.linuxde.net/nc_netcat
[42]: https://man.linuxde.net/strace
[43]: https://zhuanlan.zhihu.com/p/22194920
[44]: https://man.linuxde.net/dig
[45]: https://man.linuxde.net/dig-2
[46]: https://man.linuxde.net/nslookup
[47]: https://github.icu/articles/2019/08/29/1567060138639.html
[48]: https://github.icu/articles/2019/08/29/1567058106789.html
[49]: https://github.icu/articles/2019/08/29/1567057627672.html
[50]: https://github.icu/articles/2019/08/22/1566472573139.html
[51]: https://github.icu/articles/2019/08/30/1567127999119.html
[52]: https://github.icu/articles/2019/08/30/1567127345260.html
[53]: https://github.icu/articles/2019/08/30/1567127175232.html
[54]: https://github.icu/articles/2019/08/30/1567127101249.html
[55]: https://github.icu/search?keyword=mysql
[56]: https://centos.pkgs.org/7/mysql-5.7-x86_64/
[57]: https://github.icu/search?keyword=python
[58]: https://github.com/rabbitmq/erlang-rpm/releases
[59]: https://github.com/rabbitmq/erlang-rpm/releases/download/v21.3.8.1/erlang-21.3.8.1-1.el7.x86_64.rpm
[60]: https://github.com/rabbitmq/erlang-rpm/releases/download/v21.3.8.1/erlang-21.3.8.1-1.el6.x86_64.rpm
[61]: https://github.com/rabbitmq/rabbitmq-server/releases/
[62]: https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.el7.noarch.rpm
[63]: https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.el6.noarch.rpm
[64]: https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.suse.noarch.rpm
[65]: https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.14/rabbitmq-server-3.7.14-1.sles11.noarch.rpm
[66]: https://github.icu/articles/2019/08/28/1566986488665.html
[67]: https://github.com/Leif160519/netdata
[68]: https://github.icu/articles/2019/09/10/1568097487995.html
[69]: https://github.com/Leif160519/goaccess
[70]: https://github.icu/articles/2019/09/10/1568098665037.html
[71]: https://github.com/Leif160519/prometheus
[72]: https://github.com/Leif160519/grafana
[73]: https://grafana.com/api/dashboards/1860/revisions/20/download
[74]: https://grafana.com/grafana/dashboard
[75]: https://grafana.com/grafana/download
[76]: http://easonwu.me/2019/07/install-grafana-on-centos7.html
[77]: https://www.alibabacloud.com/help/zh/doc-detail/109434.htm
[78]: https://github.com/Leif160519/zabbix
[79]: https://www.jianshu.com/p/b2d44c733c2d
[80]: https://zhuanlan.zhihu.com/p/35064593
[81]: https://zhuanlan.zhihu.com/p/35068409
[82]: https://blog.rj-bai.com/post/144.html
[83]: https://github.icu/articles/2019/09/06/1567758755140.html
[84]: https://github.icu/articles/2019/09/06/1567758470060.html
[85]: https://github.icu/articles/2019/09/06/1567755955285.html
[86]: https://github.icu/articles/2019/09/18/1568772630383.html
[87]: https://blog.csdn.net/weixin_41004350/article/details/89521170
[88]: https://cloud.tencent.com/developer/article/1380076
[89]: https://blog.csdn.net/qq_40140473/article/details/96312452
[90]: https://blog.csdn.net/len9596/article/details/81222764
