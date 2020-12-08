#!/bin/bash
yum -y install samba
echo -n "请输入需要共享的目录（不存在则会自动创建）："
read -r share_dir
mkdir -p "${share_dir}"
chmod -R 777 "${share_dir}"
echo -n "请输入共享的名称（别名）："
read -r share_name
echo "请设置共享的root密码"
smbpasswd -a root

# 添加共享目录
cat <<EOF >> /etc/samba/smb.conf
[${share_name}]
   comment = ${share_name}
   path = ${share_dir}
   browseable = yes
   writeable = yes
   guest ok = yes
   read -r only = no
   valid user = root
EOF

# 重启samba
systemctl restart smb
# 设置samba开机自启动
systemctl enable smb

browser_url="file://ip/${share_name}/"
windows_url="\\\ip\\${share_name}"

echo "浏览器通过\"${browser_url}\",windows通过\"${windows_url}\"访问"

exit
