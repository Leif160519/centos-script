官方说明：https://docs.netdata.cloud/zh/backends/
![image](https://cloud.githubusercontent.com/assets/2662304/20649711/29f182ba-b4ce-11e6-97c8-ab2c0ab59833.png)

## 安装
### installer_for_linux.sh（Linux平台通用）
```
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
```
### installer_for_docker.sh（Docker平台，安装迅速快捷）
```
#!/usr/bin/env bash 
docker run -d --name=netdata \
  -p 19999:19999 \
  -v /etc/passwd:/host/etc/passwd:ro \
  -v /etc/group:/host/etc/group:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --cap-add SYS_PTRACE \
  --security-opt apparmor=unconfined \
  netdata/netdata
 ```

## 界面效果
浏览器输入：http://ip-address:19999
### 总览
![image.png](https://img.hacpai.com/file/2019/09/image-59110abf.png)

### CPU
![image.png](https://img.hacpai.com/file/2019/09/image-ecf958c2.png)

### 内存
![image.png](https://img.hacpai.com/file/2019/09/image-89f41a8a.png)

### Disk
![image.png](https://img.hacpai.com/file/2019/09/image-60ebcc6e.png)

### Network
![image.png](https://img.hacpai.com/file/2019/09/image-92df21fe.png)

![image.png](https://img.hacpai.com/file/2019/09/image-76767333.png)


### 用户活动
![image.png](https://img.hacpai.com/file/2019/09/image-d8841496.png)


## 添加多个监控节点
点击nodes，之后用github账号登录，成功过后可以将改节点添加你的账户下并自动跳转到所有节点页面

![image.png](https://img.hacpai.com/file/2019/09/image-d95d3000.png)

![image.png](https://img.hacpai.com/file/2019/09/image-fae07661.png)

点击其中一个节点方块，右边会自动显示该节点的一些信息
![image.png](https://img.hacpai.com/file/2019/09/image-73cd2266.png)

主界面点击任意节点名即可切换至该节点
![image.png](https://img.hacpai.com/file/2019/09/image-9cf381a1.png)

点击三角箭头即可查看真实IP地址和端口号
![image.png](https://img.hacpai.com/file/2019/09/image-d97be197.png)


