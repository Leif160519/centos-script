#!/usr/bin/env bash
# 设置grafana源
cat <<EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# 安装grafana
yum -y install grafana

# 方法2：直接下载安装包(快)
#wget -c https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-6.2.2-1.x86_64.rpm
#yum -y install grafana-6.2.2-1.x86_64.rpm
# 慢
#wget -c https://dl.grafana.com/oss/release/grafana-7.0.6-1.x86_64.rpm
#yum -y install grafana-7.0.6-1.x86_64.rpm

# 启动grafana
systemctl start grafana-server
# 查看服务状态
systemctl status grafana-server
# 设置开机自启
systemctl enable grafana-server



# 访问端口3000，默认用户名：admin，密码：admin
echo "访问端口：3000，默认用户名：admin，密码：admin"
# 插件目录：/var/lib/grafana/plugins
echo "插件目录：/var/lib/grafana/plugins"

# 下载Node Exporter for Prometheus Dashboard CN v20200628
# wget -c https://grafana.com/api/dashboards/1860/revisions/20/download -O node-exporter-full_rev20.json

# 下载Node Exporter for Prometheus Dashboard EN v20200628 
# wget -c https://grafana.com/api/dashboards/11074/revisions/4/download -O node-exporter-en_rev4.json

# 下载Node Exporter for Prometheus Dashboard 中文兼容版
# wget -c https://grafana.com/api/dashboards/11174/revisions/1/download -O node-exporter-for-prometheus-dashboard_rev1.json

# Dashboard模板仓库：https://grafana.com/grafana/dashboards
# 参考：http://easonwu.me/2019/07/install-grafana-on-centos7.html
