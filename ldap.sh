#!/bin/bash
echo -e '\033[1;32m 安装openldap \033[0m'
echo -n "请输入LDAP管理员密码："
read -r slappasswd
echo -n "请输入域名："
read -r domain
echo -n "请输入公司名称（英文）："
read -r company
#1.安装openLDAP
function installOpenLDAP(){
echo -e '\033[1;32m 1.安装openLDAP \033[0m'
echo -e '\033[1;32m yum 安装相关包  \033[0m'
yum install -y openldap openldap-clients openldap-servers
echo -e '\033[1;32m 复制一个默认配置到指定目录下,并授权，这一步一定要做，然后再启动服务，不然生产密码时会报错  \033[0m'
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
echo -e '\033[1;32m 授权给ldap用户,此用户yum安装时便会自动创建  \033[0m'
chown -R ldap. /var/lib/ldap/DB_CONFIG
echo -e '\033[1;32m 启动服务，先启动服务，配置后面再进行修改  \033[0m'
systemctl start slapd
systemctl enable slapd
echo -e '\033[1;32m 清除安装包  \033[0m'
yum -y clean all
}

#2. 修改openldap配置
#修改密码
function changepwd(){
echo -e '\033[1;32m  2. 修改openldap配置 \033[0m'
echo -e '\033[1;32m  修改密码 \033[0m'
echo -e '\033[1;32m  生成管理员密码,记录下这个密码，后面需要用到 \033[0m'
ssha=$(slappasswd -s "${slappasswd}")
echo "${ssha}"

# 新增修改密码文件,ldif为后缀，文件名随意，不要在/etc/openldap/slapd.d/目录下创建类似文件
# 生成的文件为需要通过命令去动态修改ldap现有配置，如下，我在home目录下，创建文件
echo -e '\033[1;32m  创建changepwd.ldif文件 \033[0m'
cd ~ || exit
cat <<EOF >changepwd.ldif
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: ${ssha}
EOF
# 这里解释一下这个文件的内容：
# 第一行执行配置文件，这里就表示指定为 cn=config/olcDatabase={0}config 文件。你到/etc/openldap/slapd.d/目录下就能找到此文件
# 第二行 changetype 指定类型为修改
# 第三行 add 表示添加 olcRootPW 配置项
# 第四行指定 olcRootPW 配置项的值
# 在执行下面的命令前，你可以先查看原本的olcDatabase={0}config文件，里面是没有olcRootPW这个项的，执行命令后，你再看就会新增了olcRootPW项，而且内容是我们文件中指定的值加密后的字符串

echo -e '\033[1;32m  执行命令，修改ldap配置，通过-f执行文件 \033[0m'
ldapadd -Y EXTERNAL -H ldapi:/// -f changepwd.ldif
}

#修改域名
function changedomain(){
echo -e '\033[1;32m  修改域名 \033[0m'
# 我们需要向 LDAP 中导入一些基本的 Schema。这些 Schema 文件位于 /etc/openldap/schema/ 目录中，schema控制着条目拥有哪些对象类和属性，可以自行选择需要的进行导入，
# 依次执行下面的命令，导入基础的一些配置,我这里将所有的都导入一下，其中core.ldif是默认已经加载了的，不用导入
echo -e '\033[1;32m 导入基础的一些配置 \033[0m'
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/collective.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/corba.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/duaconf.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/dyngroup.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/java.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/misc.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/openldap.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/pmi.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/ppolicy.ldif

# 修改域名，新增changedomain.ldif, 这里我自定义的域名为 ${domain}.com，管理员用户账号为admin。
# 如果要修改，则修改文件中相应的dc=${domain},dc=com为自己的域名
echo -e '\033[1;32m 修改域名，新增changedomain.ldif \033[0m'
cat <<EOF >changedomain.ldif
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=admin,dc="${domain}",dc=com" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc="${domain}",dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=admin,dc="${domain}",dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: "${ssha}"

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by dn="cn=admin,dc=${domain},dc=com" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=admin,dc=${domain},dc=com" write by * read
EOF

echo -e '\033[1;32m 执行命令，修改配置 \033[0m'
ldapmodify -Y EXTERNAL -H ldapi:/// -f changedomain.ldif
}

#启用memberof功能
function add-memberof(){
echo -e '\033[1;32m 启用memberof功能 \033[0m'
# 新增add-memberof.ldif, #开启memberof支持并新增用户支持memberof配置
echo -e '\033[1;32m 新增add-memberof.ldif, 开启memberof支持并新增用户支持memberof配置 \033[0m'
cat <<EOF >add-memberof.ldif
dn: cn=module{0},cn=config
cn: modulle{0}
objectClass: olcModuleList
objectclass: top
olcModuleload: memberof.la
olcModulePath: /usr/lib64/openldap

dn: olcOverlay={0}memberof,olcDatabase={2}hdb,cn=config
objectClass: olcConfig
objectClass: olcMemberOf
objectClass: olcOverlayConfig
objectClass: top
olcOverlay: memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
olcMemberOfGroupOC: groupOfUniqueNames
olcMemberOfMemberAD: uniqueMember
olcMemberOfMemberOfAD: memberOf
EOF


echo -e '\033[1;32m 新增refint1.ldif文件 \033[0m'
cat <<EOF >refint1.ldif
dn: cn=module{0},cn=config
add: olcmoduleload
olcmoduleload: refint
EOF


echo -e '\033[1;32m 新增refint2.ldif文件 \033[0m'
cat <<EOF >refint2.ldif
dn: olcOverlay=refint,olcDatabase={2}hdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: top
olcOverlay: refint
olcRefintAttribute: memberof uniqueMember  manager owner
EOF

# 依次执行下面命令，加载配置，顺序不能错
echo -e '\033[1;32m 加载配置 \033[0m'
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f add-memberof.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f refint1.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f refint2.ldif
}


#分配角色
function base(){
echo -e '\033[1;32m 分配角色 \033[0m'
echo -e '\033[1;32m 新增配置文件 \033[0m'
cat <<EOF >base.ldif
dn: dc=${domain},dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: ${company} Company
dc: ${domain}

dn: cn=admin,dc=${domain},dc=com
objectClass: organizationalRole
cn: admin

dn: ou=People,dc=${domain},dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=${domain},dc=com
objectClass: organizationalRole
cn: Group
EOF

# 执行命令，添加配置, 这里要注意修改域名为自己配置的域名，然后需要输入上面我们生成的密码
echo -e '\033[1;32m 执行命令，添加配置, 输入上面我们生成的密码 \033[0m'
ldapadd -x -D cn=admin,dc="${domain}",dc=com -W -f base.ldif
}


#3. 安装phpldapadmin
function installWeb(){
echo -e '\033[1;32m 3. 安装phpldapadmin \033[0m'
echo -e '\033[1;32m 卸载已安装的PHP  \033[0m'
yum remove -y "$(yum list installed | grep php | cut -d " " -f 1)"
# yum安装时，会自动安装apache和php的依赖。
# 注意： phpldapadmin很多没更新了，只支持php5，如果你服务器的环境是php7，则会有问题，页面会有各种报错
yum -y install epel-release
yum install -y phpldapadmin

# 修改apache的phpldapadmin配置文件
# 修改如下内容，放开外网访问，这里只改了2.4版本的配置，因为centos7 默认安装的apache为2.4版本。所以只需要改2.4版本的配置就可以了
# 如果不知道自己apache版本，执行 rpm -qa|grep httpd 查看apache版本
echo -e '\033[1;32m 修改apache的phpldapadmin配置文件 \033[0m'
sed -i "s/local/all granted/g" /etc/httpd/conf.d/phpldapadmin.conf


# 修改配置用DN登录ldap
echo -e '\033[1;32m 修改配置用DN登录ldap \033[0m'
# 398行，默认是使用uid进行登录，我这里改为cn，也就是用户名
sed -i "s/\$servers->setValue('login','attr','uid');/\$servers->setValue('login','attr','cn');/g" /etc/phpldapadmin/config.php

# 460行，关闭匿名登录，否则任何人都可以直接匿名登录查看所有人的信息
sed -i "s/\/\/ \$servers->setValue('login','anon_bind',true);/\$servers->setValue('login','anon_bind',false);/g" /etc/phpldapadmin/config.php

# 519行，设置用户属性的唯一性，这里我将cn,sn加上了，以确保用户名的唯一性
sed -i "s/#  \$servers->setValue('unique','attrs',array('mail','uid','uidNumber'));/\$servers->setValue('unique','attrs',array('mail','uid','uidNumber','cn','sn'));/g" /etc/phpldapadmin/config.php

# 启动apache
echo -e '\033[1;32m 启动apache \033[0m'
systemctl start httpd
systemctl enable httpd
}


#4. 登录phpldapadmin界面
function login(){
echo -e '\033[1;32m 登录phpldapadmin界面 \033[0m'
ip_address=$(ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | grep -v 172 | cut -d '/' -f1 | head -1)
echo "访问：http://${ip_address}/ldapadmin，然后使用定义的用户名和密码登陆即可"
}

installOpenLDAP
changepwd
changedomain
add-memberof
base
installWeb
login


#参考链接：https://blog.csdn.net/weixin_41004350/article/details/89521170
exit
