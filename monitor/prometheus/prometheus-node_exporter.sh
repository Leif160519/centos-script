#!/usr/bin/env bash
# 下载p8s-node_exporter
wget -c https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
# 解压到指定目录
tar -zxvf node_exporter-1.0.1.linux-amd64.tar.gz -C /usr/local
# 重命名
mv /usr/local/node_exporter-1.0.1.linux-amd64 /usr/local/node_exporter
# 启动
cat <<EOF > /lib/systemd/system/node-exporter.service
[Unit]
Description=Prometheus-node_exporter
After=network.target

[Service]
ExecStart=/usr/local/node_exporter/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启动p8s-node_exporter
systemctl start node-exporter
# 查看启动状态
systemctl status node-exporter
# 设置开机自启
systemctl enable node-exporter
# 访问端口9100
echo "访问端口9100"
