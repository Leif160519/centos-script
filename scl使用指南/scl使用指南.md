

**先介绍下 SCL 的管理方 SoftwareCollections.org**

​    SoftwareCollections.org是为Red Hat Enterprise Linux，Fedora，CentOS和Scientific Linux创建软件集合（SCL）的项目的所在地。 你可以在此处创建和托管软件集合，以及与从事SCL的其他开发人员建立联系。SoftwareCollections.org也是用户为其系统查找第三方SCL的中央存储库。

​     简而言之，SoftwareCollections.org 就是一些软件集合的托管方，类似于 MicroSoft Store.

**什么是SCL**

原文：
    With Software Collections, you can build and concurrently install multiple versions of the same software components on your system. Software Collections have no impact on the system versions of the packages installed by any of the conventional RPM package management utilities.

​        翻译一下就是说使用 Software Collection 可以在系统上同时安装一个软件的多个版本并且不会影响你系统原本的软件包。

**看一下官方说的优点：**

- Do not overwrite system files （不会覆盖系统文件）
- Are designed to avoid conflicts with system files （不会与系统文件冲突）
- Require no changes to the RPM package manager （不需要更改RPM包管理器）
- Need only minor changes to the spec file （只要稍微改改spec文件就成）
- Allow you to build a conventional package and a Software Collection package with a single spec file （可以用spec文件构建传统包和 Software Collection 包）
- Uniquely name all included packages （所有文件都是唯一命名的）
- Do not conflict with updated packages （不会与更新的包冲突）
- Can depend on other Software Collections （软件集合间可以相互依赖）

**什么是上面提到的 spec 文件呢**

​       spec文件只是一个具有特殊语法的文本文件。spec文件中包含了软件包的诸多信息，如软件包的名字、版本、类别、说明摘要、创建时要执行什么指令、安装时要执行什么操作，以及软件包所要包含的文件列表等。[来源](<https://blog.csdn.net/younger_china/article/details/53131105>)

**再了解一下Software Collection的实现原理**

找到的一段原文：
	When you run the **scl** tool, it creates a child process (subshell) of the current shell. Running the command again then creates a subshell of the subshell.

大意是说运行 scl 工具的时候会创建一个当前 shell 的子 shell来替代当前 shell。

验证一下

```shell
[root@carl ~]# ps | grep $$
 9847 pts/0    00:00:00 bash    # 开启 scl 之前
[root@carl rh]# scl enable devtoolset-3 bash  # 开启 scl
[root@carl rh]# ps | grep $$
 9933 pts/0    00:00:00 bash    # 开启 scl 之后
```

所以我的理解是新开启的子 shell 会修改部分环境变量，通过临时覆盖系统中的工具集来来达到修改默认软件版本的功能。修改环境变量的脚本在 `/opt/rh/` 目录下，不过你需要先安装个工具集才可以看到具体的脚本。比如我当前安装了工具集`devtoolset-3`，我在 `/opt/rh/devtoolset-3/`目录下就可以找到一个叫`enable`的脚本。脚本内容如下

```bash
# This collection has a build-time dependency on maven30, so
# General environment variables
export PATH=/opt/rh/devtoolset-3/root/usr/bin${PATH:+:${PATH}}
export MANPATH=/opt/rh/devtoolset-3/root/usr/share/man:${MANPATH}
export INFOPATH=/opt/rh/devtoolset-3/root/usr/share/info${INFOPATH:+:${INFOPATH}}

# Needed by Java Packages Tools to locate java.conf
export JAVACONFDIRS="/opt/rh/devtoolset-3/root/etc/java:${JAVACONFDIRS:-/etc/java}"

# Required by XMvn to locate its configuration files
export XDG_CONFIG_DIRS="/opt/rh/devtoolset-3/root/etc/xdg:${XDG_CONFIG_DIRS:-/etc/xdg}"
export XDG_DATA_DIRS="/opt/rh/devtoolset-3/root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

export PCP_DIR=/opt/rh/devtoolset-3/root
# Some perl Ext::MakeMaker versions install things under /usr/lib/perl5
# even though the system otherwise would go to /usr/lib64/perl5.
export PERL5LIB=/opt/rh/devtoolset-3/root//usr/lib64/perl5/vendor_perl:/opt/rh/devtoolset-3/root/usr/lib/perl5:/opt/rh/devtoolset-3/root//usr/share/perl5/vendor_perl${PERL5LIB:+:${PERL5LIB}}
# bz847911 workaround:
# we need to evaluate rpm's installed run-time % { _libdir }, not rpmbuild time
# or else /etc/ld.so.conf.d files?
rpmlibdir=$(rpm --eval "%{_libdir}")
# bz1017604: On 64-bit hosts, we should include also the 32-bit library path.
if [ "$rpmlibdir" != "${rpmlibdir/lib64/}" ]; then
  rpmlibdir32=":/opt/rh/devtoolset-3/root${rpmlibdir/lib64/lib}"
fi
export LD_LIBRARY_PATH=/opt/rh/devtoolset-3/root$rpmlibdir$rpmlibdir32${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
# duplicate python site.py logic for sitepackages
pythonvers=2.6
export PYTHONPATH=/opt/rh/devtoolset-3/root/usr/lib64/python$pythonvers/site-packages:/opt/rh/devtoolset-3/root/usr/lib/python$pythonvers/site-packages${PYTHONPATH:+:${PYTHONPATH}}
```

**上面提到了devtoolset，那么先了解下什么是 devtoolset**

先看看官方的介绍：

 Developer Toolset is designed for developers working on CentOS or Red Hat Enterprise Linux platform. It provides current versions of the GNU Compiler Collection, GNU Debugger, and other development, debugging, and performance monitoring tools.[链接](<https://www.softwarecollections.org/en/scls/rhscl/devtoolset-7/>)

大意是说 devtoolset 为使用 CentOS 和 Red Hat 的程序员 提供了当前版本的GCC之类的工具。

也可以看看Reddit上面对 devtoolset与C++的一个讨论贴，总体来说评价还是不错的。 [链接](<https://www.reddit.com/r/cpp/comments/86juhc/devtoolset_is_a_game_changer_for_c_development_on/>)

另外当前最新版的 devtoolset 是 devtoolset-8。

**SCL 使用引导**

我目前使用的是 CentOS 6， 所以就拿它来实际使用一下 SCL 吧, 步骤基本是参照的官方的[Quick Start](<https://www.softwarecollections.org/en/docs/>)

1. 安装 `centos-release-scl`

   ```shell
   yum install centos-release-scl
   ```

   如果你使用的是 Red Hat，需要启用 RHSCL源，还需要提供对 RHSCL 的访问权限。

   ```shell
   yum-config-manager --enable rhel-server-rhscl-7-rpms
   ```

   具体内容可以参考[Red Hat Developer Toolset](<https://developers.redhat.com/products/developertoolset/hello-world/#fndtn-windows>)

2. 安装你喜欢的 SCL 包或者集合，所有的 SCL 列表在 [Directory](<https://www.softwarecollections.org/en/scls/>)，可以去找找自己需要的，我这里的示例是使用 `devtoolset-6`。

   ```shell
   yum install devtoolset-6

   # wget http://mirror.centos.org/centos/6/sclo/x86_64/rh/devtoolset-6/devtoolset-6-6.0-6.el6.x86_64.rpm
   # yum install devtoolset-6-6.0-6.el6.x86_64.rpm
   ```

   如果第一条命令不可用，可以使用 softwarecollection提供的rpm包，在 softwarecollection 网站内查询相应的包名，会跳转到包的介绍页面，页面上方是安装指导，下方是适合各系统的 rpm 包的链接。

3. 开启 `devtoolset-6`

   ```shell
   scl enable devtoolset-6 bash
   ```

4. 这里我们简单的测试一下 GCC 的使用

   ```shell
   [root@carl ~]# gcc -v
   Using built-in specs.
   Target: x86_64-redhat-linux
   # 省略部分输出信息...
   gcc version 4.4.7 20120313 (Red Hat 4.4.7-23) (GCC)
   [root@carl ~]# scl enable devtoolset-6 bash
   [root@carl ~]# gcc -v
   Using built-in specs.
   COLLECT_GCC=gcc
   COLLECT_LTO_WRAPPER=/opt/rh/devtoolset-6/root/usr/libexec/gcc/x86_64-redhat-linux/6.3.1/lto-wrapper
   Target: x86_64-redhat-linux
   # 省略部分输出信息...
   gcc version 6.3.1 20170216 (Red Hat 6.3.1-3) (GCC)
   ```

   可以很明显的看到 GCC 版本产生了变化。

5. 退出`devtoolset`

   ```shell
   exit
   ```

6. 卸载`devtoolset-6`

   ```shell
   yum remove devtoolset-6\*
   ```

上面这样的确可以在不同版本的软件中切换，但是也有一个缺点，就是只能在当前终端中使用，一旦退出终端，下次还要使用相应工具集就需要再进行一遍上述操作。不过这也是官方推荐的方法。如果你实在是想进行全局替换，可以考虑将上述命令写入启动脚本。

**结束**

上面介绍的知识 SCL 的很基础的功能，之后有时间我再介绍一下如何使用 SCL 创建自己的软件集合之类的功能



>
>
>参考资料
>
>[About the SCL project](<https://www.softwarecollections.org/en/>)
>
>[RedHat6系列Devtool-Set](https://segmentfault.com/a/1190000004193587)
>
>[CentOS/RHEL 开发环境之 devtoolset](<http://blog.fungo.me/2016/03/centos-development-env/>)
>
>[Red Hat Developer Toolset](<https://developers.redhat.com/products/developertoolset/hello-world/#fndtn-windows>)
>
>
