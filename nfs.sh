#!/bin/bash
yum -y install nfs-utils
echo -n "请输入需要共享的目录（不存在的会自动创建）："
read -r share_dir
mkdir -p "${share_dir}"
chmod -R 777 "${share_dir}"
echo -n "请输入允许访问nfs的IP段,如'192.168.1.0/24'（若允许所有主机都可访问，请输入'*'）："
read -r ip
# 添加共享目录
cat <<EOF >> /etc/exports
${share_dir} ${ip}(rw,sync,no_subtree_check,no_root_squash)
EOF
# 重启nfs服务
systemctl restart nfs-server
# 设置nfs开机自启动
systemctl enable nfs-server

#不重启nfs服务，刷新配置
#exportfs -arv

browser_url="file://ip${share_dir}"
windows_url="\\\ip\\${share_dir}"

echo "浏览器通过\"${browser_url}\",windows通过\"${windows_url}\"访问"
exit
