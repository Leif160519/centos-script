## 1. 启用nginx status配置
在location添加下列内容：
```
server {
    location /ngx_status
    {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
```

示例：
```
······
    server {
        listen 80;
        server_name example.com;
       
       location / {
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Host $http_host;
            proxy_pass http://127.0.0.1:8080;
        }

        location /goaccess {
            root /usr/local/src;
        }

        location /ngx_status
        {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
        }
        
······
```

## 2. 重载nginx
```
ngixn -s reload
```

## 3. 打开status页面
```
curl http://127.0.0.1/ngx_status
Active connections: 3
server accepts handled requests
 123630 123630 477618
Reading: 0 Writing: 1 Waiting: 2
```

> 若启用https和域名访问，则直接将IP地址换成域名：`curl https://domain/ngx_status`

## 4. nginx status详解
- active connections – 活跃的连接数量
- server accepts handled requests — 总共处理了11989个连接 , 成功创建11989次握手, 总共处理了11991个请求
- reading — 读取客户端的连接数.
- writing — 响应数据到客户端的数量
- waiting — 开启 keep-alive 的情况下,这个值等于 active – (reading+writing), 意思就是 Nginx 已经处理完正在等候下一次请求指令的驻留连接.

以上为nginx性能计数，我们除了监控以上数据，还需要监控nginx进程状态，并且配置触发器

## 2.zabbix客户端配置
### 2.1 编写客户端脚本

- /etc/zabbix/zabbix_agentd.d/nginx_status.sh

```
#!/bin/bash
HOST="127.0.0.1"
PORT="80"
# 检测nginx进程是否存在
function ping() {
	/usr/sbin/pidof nginx | wc -l
}

# 检测nginx性能

function active() {
	/usr/bin/curl "http://$HOST:$PORT/ngx_status/"  2>/dev/null | grep 'Active' | awk '{print $NF}'
}
function reading() {
	/usr/bin/curl "http://$HOST:$PORT/ngx_status/"  2>/dev/null | grep 'Reading' | awk '{print $2}'
}
function writing() {
	/usr/bin/curl "http://$HOST:$PORT/ngx_status/"  2>/dev/null | grep 'Writing' | awk '{print $4}'
}
function waiting() {
	/usr/bin/curl "http://$HOST:$PORT/ngx_status/"  2>/dev/null | grep 'Waiting' | awk '{print $6}'
}
function accepts() {
	/usr/bin/curl "http://$HOST:$PORT/ngx_status/"  2>/dev/null | awk NR==3 | awk '{print $1}'
}
function handled() {
	/usr/bin/curl "http://$HOST:$PORT/ngx_status/"  2>/dev/null | awk NR==3 | awk '{print $2}'
}
function requests() {
	/usr/bin/curl "http://$HOST:$PORT/ngx_status/"  2>/dev/null | awk NR==3 | awk '{print $3}'
}

# 执行function
$1
```

> 若采用`https`的域名方式访问，则将脚本中的`http`替换成`https`，IP地址替换成域名即可

### 2.2 添加脚本执行权限
```
chmod +x /etc/zabbix/zabbix_agentd.d/nginx_status.sh
```

### 2.3 自定义UserParameter

- /etc/zabbix/zabbix_agentd.d/nginx.conf

```
UserParameter=nginx.status[*],/etc/zabbix/zabbix_agentd.d/nginx_status.sh $1
```

### 2.4 重启zabbix-agent
```
systemctl restart zabbix-agent
```

### 2.5 zabbix_get获取数据
```
zabbix_get -s 127.0.0.1  -p 10050 -k 'nginx.status[accepts]'
123833
zabbix_get -s 127.0.0.1  -p 10050 -k 'nginx.status[ping]'
1
```

## 3.zabbix web端配置

### 3.1 导入Template App NGINX模板

- Template nginx status.xml

```
<?xml version="1.0" encoding="utf-8"?>
<zabbix_export>
    <version>3.0</version>
    <date>2017-07-17T09:37:18Z</date>
    <groups>
        <group>
            <name>Templates</name>
        </group>
    </groups>
    <templates>
        <template>
            <template>Template nginx status</template>
            <name>Template nginx status</name>
            <description>nginx监控模板</description>
            <groups>
                <group>
                    <name>Templates</name>
                </group>
            </groups>
            <applications>
                <application>
                    <name>nginx</name>
                </application>
            </applications>
            <items>
                <item>
                    <name>nginx status server accepts</name>
                    <type>0</type>
                    <snmp_community />
                    <multiplier>0</multiplier>
                    <snmp_oid />
                    <key>nginx.status[accepts]</key>
                    <delay>60</delay>
                    <history>90</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts />
                    <units />
                    <delta>1</delta>
                    <snmpv3_contextname />
                    <snmpv3_securityname />
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase />
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase />
                    <formula>1</formula>
                    <delay_flex />
                    <params />
                    <ipmi_sensor />
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username />
                    <password />
                    <publickey />
                    <privatekey />
                    <port />
                    <description>accepts</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>nginx</name>
                        </application>
                    </applications>
                    <valuemap />
                    <logtimefmt />
                </item>
                <item>
                    <name>nginx status connections active</name>
                    <type>0</type>
                    <snmp_community />
                    <multiplier>0</multiplier>
                    <snmp_oid />
                    <key>nginx.status[active]</key>
                    <delay>60</delay>
                    <history>90</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts />
                    <units />
                    <delta>0</delta>
                    <snmpv3_contextname />
                    <snmpv3_securityname />
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase />
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase />
                    <formula>1</formula>
                    <delay_flex />
                    <params />
                    <ipmi_sensor />
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username />
                    <password />
                    <publickey />
                    <privatekey />
                    <port />
                    <description>active</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>nginx</name>
                        </application>
                    </applications>
                    <valuemap />
                    <logtimefmt />
                </item>
                <item>
                    <name>nginx status server handled</name>
                    <type>0</type>
                    <snmp_community />
                    <multiplier>0</multiplier>
                    <snmp_oid />
                    <key>nginx.status[handled]</key>
                    <delay>60</delay>
                    <history>90</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts />
                    <units />
                    <delta>1</delta>
                    <snmpv3_contextname />
                    <snmpv3_securityname />
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase />
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase />
                    <formula>1</formula>
                    <delay_flex />
                    <params />
                    <ipmi_sensor />
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username />
                    <password />
                    <publickey />
                    <privatekey />
                    <port />
                    <description>handled</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>nginx</name>
                        </application>
                    </applications>
                    <valuemap />
                    <logtimefmt />
                </item>
                <item>
                    <name>nginx status PING</name>
                    <type>0</type>
                    <snmp_community />
                    <multiplier>0</multiplier>
                    <snmp_oid />
                    <key>nginx.status[ping]</key>
                    <delay>60</delay>
                    <history>30</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts />
                    <units />
                    <delta>0</delta>
                    <snmpv3_contextname />
                    <snmpv3_securityname />
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase />
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase />
                    <formula>1</formula>
                    <delay_flex />
                    <params />
                    <ipmi_sensor />
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username />
                    <password />
                    <publickey />
                    <privatekey />
                    <port />
                    <description>is live</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>nginx</name>
                        </application>
                    </applications>
                    <valuemap>
                        <name>Service state</name>
                    </valuemap>
                    <logtimefmt />
                </item>
                <item>
                    <name>nginx status connections reading</name>
                    <type>0</type>
                    <snmp_community />
                    <multiplier>0</multiplier>
                    <snmp_oid />
                    <key>nginx.status[reading]</key>
                    <delay>60</delay>
                    <history>90</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts />
                    <units />
                    <delta>0</delta>
                    <snmpv3_contextname />
                    <snmpv3_securityname />
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase />
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase />
                    <formula>1</formula>
                    <delay_flex />
                    <params />
                    <ipmi_sensor />
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username />
                    <password />
                    <publickey />
                    <privatekey />
                    <port />
                    <description>reading</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>nginx</name>
                        </application>
                    </applications>
                    <valuemap />
                    <logtimefmt />
                </item>
                <item>
                    <name>nginx status server requests</name>
                    <type>0</type>
                    <snmp_community />
                    <multiplier>0</multiplier>
                    <snmp_oid />
                    <key>nginx.status[requests]</key>
                    <delay>60</delay>
                    <history>90</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts />
                    <units />
                    <delta>1</delta>
                    <snmpv3_contextname />
                    <snmpv3_securityname />
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase />
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase />
                    <formula>1</formula>
                    <delay_flex />
                    <params />
                    <ipmi_sensor />
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username />
                    <password />
                    <publickey />
                    <privatekey />
                    <port />
                    <description>requests</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>nginx</name>
                        </application>
                    </applications>
                    <valuemap />
                    <logtimefmt />
                </item>
                <item>
                    <name>nginx status connections waiting</name>
                    <type>0</type>
                    <snmp_community />
                    <multiplier>0</multiplier>
                    <snmp_oid />
                    <key>nginx.status[waiting]</key>
                    <delay>60</delay>
                    <history>90</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts />
                    <units />
                    <delta>0</delta>
                    <snmpv3_contextname />
                    <snmpv3_securityname />
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase />
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase />
                    <formula>1</formula>
                    <delay_flex />
                    <params />
                    <ipmi_sensor />
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username />
                    <password />
                    <publickey />
                    <privatekey />
                    <port />
                    <description>waiting</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>nginx</name>
                        </application>
                    </applications>
                    <valuemap />
                    <logtimefmt />
                </item>
                <item>
                    <name>nginx status connections writing</name>
                    <type>0</type>
                    <snmp_community />
                    <multiplier>0</multiplier>
                    <snmp_oid />
                    <key>nginx.status[writing]</key>
                    <delay>60</delay>
                    <history>90</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts />
                    <units />
                    <delta>0</delta>
                    <snmpv3_contextname />
                    <snmpv3_securityname />
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase />
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase />
                    <formula>1</formula>
                    <delay_flex />
                    <params />
                    <ipmi_sensor />
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username />
                    <password />
                    <publickey />
                    <privatekey />
                    <port />
                    <description>writing</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>nginx</name>
                        </application>
                    </applications>
                    <valuemap />
                    <logtimefmt />
                </item>
            </items>
            <discovery_rules />
            <macros />
            <templates />
            <screens />
        </template>
    </templates>
    <triggers>
        <trigger>
            <expression>{Template nginx status:nginx.status[ping].last(0)}=0 and {Template nginx status:nginx.status[ping].last(1)}=0</expression>
            <name>nginx is down!</name>
            <url />
            <status>0</status>
            <priority>4</priority>
            <description />
            <type>0</type>
            <dependencies />
        </trigger>
    </triggers>
    <graphs>
        <graph>
            <name>nginx status</name>
            <width>900</width>
            <height>200</height>
            <yaxismin>0.0000</yaxismin>
            <yaxismax>100.0000</yaxismax>
            <show_work_period>1</show_work_period>
            <show_triggers>1</show_triggers>
            <type>0</type>
            <show_legend>1</show_legend>
            <show_3d>0</show_3d>
            <percent_left>0.0000</percent_left>
            <percent_right>0.0000</percent_right>
            <ymin_type_1>0</ymin_type_1>
            <ymax_type_1>0</ymax_type_1>
            <ymin_item_1>0</ymin_item_1>
            <ymax_item_1>0</ymax_item_1>
            <graph_items>
                <graph_item>
                    <sortorder>0</sortorder>
                    <drawtype>0</drawtype>
                    <color>1A7C11</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>2</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template nginx status</host>
                        <key>nginx.status[active]</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>1</sortorder>
                    <drawtype>0</drawtype>
                    <color>F63100</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>2</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template nginx status</host>
                        <key>nginx.status[reading]</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>2</sortorder>
                    <drawtype>0</drawtype>
                    <color>2774A4</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>2</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template nginx status</host>
                        <key>nginx.status[waiting]</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>3</sortorder>
                    <drawtype>0</drawtype>
                    <color>A54F10</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>2</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template nginx status</host>
                        <key>nginx.status[writing]</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>4</sortorder>
                    <drawtype>0</drawtype>
                    <color>FC6EA3</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>2</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template nginx status</host>
                        <key>nginx.status[accepts]</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>5</sortorder>
                    <drawtype>0</drawtype>
                    <color>6C59DC</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>2</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template nginx status</host>
                        <key>nginx.status[handled]</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>6</sortorder>
                    <drawtype>0</drawtype>
                    <color>AC8C14</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>2</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template nginx status</host>
                        <key>nginx.status[requests]</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
    </graphs>
    <value_maps>
        <value_map>
            <name>Service state</name>
            <mappings>
                <mapping>
                    <value>0</value>
                    <newvalue>Down</newvalue>
                </mapping>
                <mapping>
                    <value>1</value>
                    <newvalue>Up</newvalue>
                </mapping>
            </mappings>
        </value_map>
    </value_maps>
</zabbix_export>
```

### 3.2 添加模板

![image.png](https://img.hacpai.com/file/2020/04/image-520acfbf.png)

> 注意：不要添加错了，zabbix自带nginx模板不过我们不用

### 3.3 效果
![image.png](https://img.hacpai.com/file/2020/04/image-3f9e82a2.png)


## 4.参考
本文摘自：[Zabbix监控Nginx性能的实现方式](https://www.linuxidc.com/Linux/2018-11/155480.htm)