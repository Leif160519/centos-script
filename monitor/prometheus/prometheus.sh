#!/usr/bin/env bash
# 下载p8s
wget -c https://github.com/prometheus/prometheus/releases/download/v2.19.2/prometheus-2.19.2.linux-amd64.tar.gz
# 解压到指定目录
tar -zxvf prometheus-2.19.2.linux-amd64.tar.gz -C /usr/local
# 重命名
mv /usr/local/prometheus-2.19.2.linux-amd64 /usr/local/prometheus
# 启动
cat <<EOF > /lib/systemd/system/prometheus.service
[Unit]
Description=Prometheus
After=network.target

[Service]
ExecStart=/usr/local/prometheus/prometheus --config.file=/usr/local/prometheus/prometheus.yml --web.enable-lifecycle
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启动p8s
systemctl start prometheus
# 查看启动状态
systemctl status prometheus
# 设置开机自启
systemctl enable prometheus
# 访问端口9090
echo "访问端口9090"

# 添加监控节点
#cat <<EOF >> /usr/local/prometheus/prometheus.yml
#  - job_name: 'node'
#    static_configs:
#    - targets: ['10.1.26.76:9100','localhost:9100']
#EOF
# 热刷新配置
#kill -HUP `ps -e | grep prometheus | awk '{print $1}'`

#/******/
# 第一种，向prometheus进行发信号
#kill -HUP  pid

# 第二种，向prometheus发送HTTP请求
# /-/reload只接收POST请求，并且需要在启动prometheus进程时，指定 --web.enable-lifecycle
#curl -XPOST http://ip:port/-/reload
#/******/
