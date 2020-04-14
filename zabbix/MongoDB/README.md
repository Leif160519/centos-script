[zabbix官方教程](https://www.zabbix.com/cn/integrations/mongodb)
[github地址](https://github.com/omni-lchen/zabbix-mongodb)

## 1.准备工作
由于mongodb检测涉及到Python的`pymongo`模块和`zabbix_sender`命令，故先安装这两个模块：
```
pip install pymongo
yum -y install zabbix-sender
```

注意：若没有pip命令则先安装pip：`yum -y install python-pip`

## 2.将mongodb-stats.sh和zabbix-mongodb.py分别放到指定目录下

- /etc/zabbix/zabbix_agentd.d/mongodb-stats.sh

```
#!/bin/bash

# Date:                 22/01/2017
# Author:               Long Chen
# Description:          A script to send MongoDB stats to zabbix server by using zabbix sender
# Requires:             Zabbix Sender, zabbix-mongodb.py

get_MongoDB_metrics(){
python /etc/zabbix/zabbix_agentd.d/zabbix-mongodb.py
}

# Send the results to zabbix server by using zabbix sender
result=$(get_MongoDB_metrics | /usr/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -i - 2>&1)
response=$(echo "$result" | awk -F ';' '$1 ~ /^info/ && match($1,/[0-9].*$/) {sum+=substr($1,RSTART,RLENGTH)} END {print sum}')
if [ -n "$response" ]; then
        echo "$response"
else
        echo "$result"
fi
```

- /etc/zabbix/zabbix_agentd.d/zabbix-mongodb.py

```
#!/usr/bin/env python
"""
Date: 03/01/2017
Author: Long Chen
Description: A script to get MongoDB metrics
Requires: MongoClient in python
"""

from calendar import timegm
from time import gmtime

from pymongo import MongoClient, errors
from sys import exit

import json

class MongoDB(object):
    """main script class"""
    # pylint: disable=too-many-instance-attributes
    def __init__(self):
        self.mongo_host = "127.0.0.1"
        self.mongo_port = 27017
        self.mongo_db = ["admin", ]
        self.mongo_user = None
        self.mongo_password = None
        self.__conn = None
        self.__dbnames = None
        self.__metrics = []

    def connect(self):
        """Connect to MongoDB"""
        if self.__conn is None:
            if self.mongo_user is None:
                try:
                    self.__conn = MongoClient('mongodb://%s:%s' %
                                              (self.mongo_host,
                                               self.mongo_port))
                except errors.PyMongoError as py_mongo_error:
                    print('Error in MongoDB connection: %s' %
                          str(py_mongo_error))
            else:
                try:
                    self.__conn = MongoClient('mongodb://%s:%s@%s:%s' %
                                              (self.mongo_user,
                                               self.mongo_password,
                                               self.mongo_host,
                                               self.mongo_port))
                except errors.PyMongoError as py_mongo_error:
                    print('Error in MongoDB connection: %s' %
                          str(py_mongo_error))

    def add_metrics(self, k, v):
        """add each metric to the metrics list"""
        dict_metrics = {}
        dict_metrics['key'] = k
        dict_metrics['value'] = v
        self.__metrics.append(dict_metrics)

    def print_metrics(self):
        """print out all metrics"""
        metrics = self.__metrics
        for metric in metrics:
            zabbix_item_key = str(metric['key'])
            zabbix_item_value = str(metric['value'])
            print('- ' + zabbix_item_key + ' ' + zabbix_item_value)

    def get_db_names(self):
        """get a list of DB names"""
        if self.__conn is None:
            self.connect()
        db_handler = self.__conn[self.mongo_db[0]]

        master = db_handler.command('isMaster')['ismaster']
        dict_metrics = {}
        dict_metrics['key'] = 'mongodb.ismaster'
        if master:
            dict_metrics['value'] = 1
            db_names = self.__conn.database_names()
            self.__dbnames = db_names
        else:
            dict_metrics['value'] = 0
        self.__metrics.append(dict_metrics)

    def get_mongo_db_lld(self):
        """print DB list in json format, to be used for
        mongo db discovery in zabbix"""
        if self.__dbnames is None:
            db_names = self.get_db_names()
        else:
            db_names = self.__dbnames
        dict_metrics = {}
        db_list = []
        dict_metrics['key'] = 'mongodb.discovery'
        dict_metrics['value'] = {"data": db_list}
        if db_names is not None:
            for db_name in db_names:
                dict_lld_metric = {}
                dict_lld_metric['{#MONGODBNAME}'] = db_name
                db_list.append(dict_lld_metric)
            dict_metrics['value'] = '{"data": ' + json.dumps(db_list) + '}'
        self.__metrics.insert(0, dict_metrics)

    def get_oplog(self):
        """get replica set oplog information"""
        if self.__conn is None:
            self.connect()
        db_handler = self.__conn['local']

        coll = db_handler.oplog.rs

        op_first = (coll.find().sort('$natural', 1).limit(1))
        op_last = (coll.find().sort('$natural', -1).limit(1))

        # if host is not a member of replica set, without this check we will
        # raise StopIteration as guided in
        # http://api.mongodb.com/python/current/api/pymongo/cursor.html

        if op_first.count() > 0 and op_last.count() > 0:
            op_fst = (op_first.next())['ts'].time
            op_last_st = op_last[0]['ts']
            op_lst = (op_last.next())['ts'].time

            status = round(float(op_lst - op_fst), 1)
            self.add_metrics('mongodb.oplog', status)

            current_time = timegm(gmtime())
            oplog = int(((str(op_last_st).split('('))[1].split(','))[0])
            self.add_metrics('mongodb.oplog-sync', (current_time - oplog))


    def get_maintenance(self):
        """get replica set maintenance info"""
        if self.__conn is None:
            self.connect()
        db_handler = self.__conn

        fsync_locked = int(db_handler.is_locked)
        self.add_metrics('mongodb.fsync-locked', fsync_locked)

        try:
            config = db_handler.admin.command("replSetGetConfig", 1)
            connstring = (self.mongo_host + ':' + str(self.mongo_port))
            connstrings = list()

            for i in range(0, len(config['config']['members'])):
                host = config['config']['members'][i]['host']
                connstrings.append(host)

                if connstring in host:
                    priority = config['config']['members'][i]['priority']
                    hidden = int(config['config']['members'][i]['hidden'])

            self.add_metrics('mongodb.priority', priority)
            self.add_metrics('mongodb.hidden', hidden)
        except errors.PyMongoError:
            print ('Error while fetching replica set configuration.'
                   'Not a member of replica set?')
        except UnboundLocalError:
            print ('Cannot use this mongo host: must be one of ' + ','.join(connstrings))
            exit(1)

    def get_server_status_metrics(self):
        """get server status"""
        if self.__conn is None:
            self.connect()
        db_handler = self.__conn[self.mongo_db[0]]
        ss = db_handler.command('serverStatus')

        # db info
        self.add_metrics('mongodb.version', ss['version'])
        self.add_metrics('mongodb.storageEngine', ss['storageEngine']['name'])
        self.add_metrics('mongodb.uptime', int(ss['uptime']))
        self.add_metrics('mongodb.okstatus', int(ss['ok']))

        # asserts
        for k, v in ss['asserts'].items():
            self.add_metrics('mongodb.asserts.' + k, v)

        # operations
        for k, v in ss['opcounters'].items():
            self.add_metrics('mongodb.operation.' + k, v)

        # memory
        for k in ['resident', 'virtual', 'mapped', 'mappedWithJournal']:
            self.add_metrics('mongodb.memory.' + k, ss['mem'][k])

        # connections
        for k, v in ss['connections'].items():
            self.add_metrics('mongodb.connection.' + k, v)

        # network
        for k, v in ss['network'].items():
            self.add_metrics('mongodb.network.' + k, v)

        # extra info
        self.add_metrics('mongodb.page.faults',
                         ss['extra_info']['page_faults'])

        #wired tiger
        if ss['storageEngine']['name'] == 'wiredTiger':
            self.add_metrics('mongodb.used-cache',
                             ss['wiredTiger']['cache']
                             ["bytes currently in the cache"])
            self.add_metrics('mongodb.total-cache',
                             ss['wiredTiger']['cache']
                             ["maximum bytes configured"])
            self.add_metrics('mongodb.dirty-cache',
                             ss['wiredTiger']['cache']
                             ["tracked dirty bytes in the cache"])

        # global lock
        lock_total_time = ss['globalLock']['totalTime']
        self.add_metrics('mongodb.globalLock.totalTime', lock_total_time)
        for k, v in ss['globalLock']['currentQueue'].items():
            self.add_metrics('mongodb.globalLock.currentQueue.' + k, v)
        for k, v in ss['globalLock']['activeClients'].items():
            self.add_metrics('mongodb.globalLock.activeClients.' + k, v)

    def get_db_stats_metrics(self):
        """get DB stats for each DB"""
        if self.__conn is None:
            self.connect()
        if self.__dbnames is None:
            self.get_db_names()
        if self.__dbnames is not None:
            for mongo_db in self.__dbnames:
                db_handler = self.__conn[mongo_db]
                dbs = db_handler.command('dbstats')
                for k, v in dbs.items():
                    if k in ['storageSize', 'ok', 'avgObjSize', 'indexes',
                             'objects', 'collections', 'fileSize',
                             'numExtents', 'dataSize', 'indexSize',
                             'nsSizeMB']:
                        self.add_metrics('mongodb.stats.' + k +
                                         '[' + mongo_db + ']', int(v))
    def close(self):
        """close connection to mongo"""
        if self.__conn is not None:
            self.__conn.close()

if __name__ == '__main__':
    mongodb = MongoDB()
    mongodb.get_db_names()
    mongodb.get_mongo_db_lld()
    mongodb.get_oplog()
    mongodb.get_maintenance()
    mongodb.get_server_status_metrics()
    mongodb.get_db_stats_metrics()
    mongodb.print_metrics()
    mongodb.close()
```

脚本赋予可执行权限：
```
chmod +x mongodb-stats.sh
chmod +x zabbix-mongodb.py
```

## 3.配置zabbix监控mongodb的配置文件

- /etc/zabbix/zabbix_agentd.d/mongodb.conf

```
# mongodb stats
UserParameter=mongodb.zabbix.sender,/etc/zabbix/zabbix_agentd.d/mongodb-stats.sh
```

## 4.重启zabbix-agent
```
systemctl restart zabbix-agent
```

## 5.导入mongodb模板

原地址：[github](https://raw.githubusercontent.com/omni-lchen/zabbix-mongodb/master/Templates/Template_MongoDB.xml)
- Template_MongoDB.xml

```
<?xml version="1.0" encoding="UTF-8"?>
<zabbix_export>
    <version>3.2</version>
    <date>2017-08-14T15:50:26Z</date>
    <groups>
        <group>
            <name>Templates</name>
        </group>
    </groups>
    <templates>
        <template>
            <template>Template MongoDB</template>
            <name>Template MongoDB</name>
            <description/>
            <groups>
                <group>
                    <name>Templates</name>
                </group>
            </groups>
            <applications>
                <application>
                    <name>MongoDB</name>
                </application>
            </applications>
            <items>
                <item>
                    <name>MongoDB::asserts::msg count</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.asserts.msg</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The number of message assertions raised since the MongoDB process started. Check the log file for more information about these messages.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::asserts::regular count</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.asserts.regular</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The number of regular assertions raised since the MongoDB process started. Check the log file for more information about these messages.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::asserts::rollovers count</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.asserts.rollovers</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The number of times that the rollover counters have rolled over since the last time the MongoDB process started. The counters will rollover to zero after 230 assertions. Use this value to provide context to the other values in the asserts data structure.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::asserts::user count</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.asserts.user</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The number of “user asserts” that have occurred since the last time the MongogDB process started. These are errors that user may generate, such as out of disk space or duplicate key. You can prevent these assertions by fixing a problem with your application or deployment. Check the MongoDB log for more information.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::asserts::warning count</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.asserts.warning</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The number of warnings raised since the MongoDB process started. Check the log file for more information about these warnings.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::connection::connection available</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.connection.available</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The number of unused incoming connections available. Consider this value in combination with the value of connections.current to understand the connection load on the database, and the UNIX ulimit Settings document for more information about system thresholds on available connections.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::connection::current connection</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.connection.current</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The number of incoming connections from clients to the database server . This number includes the current shell session. Consider the value of connections.available to add more context to this datum.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::connection::connection rate</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.connection.totalCreated</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>conn/s</units>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>Count of all incoming connections created to the server. This number includes connections that have since closed.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::Wired Tiger Dirty Cache</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.dirty-cache</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>B</units>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::FsyncLock</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.fsync-locked</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>3</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>Tells the user if the MongoDB has fsync lock enabled, this prevents write operations and is turned on during some maintenance scripts.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::globalLock::activeClients::readers</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.globalLock.activeClients.readers</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The number of the active client connections performing read operations.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::globalLock::activeClients::total</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.globalLock.activeClients.total</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The total number of operations queued waiting for the lock (i.e., the sum of globalLock.currentQueue.readers and globalLock.currentQueue.writers).</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::globalLock::activeClients::writers</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.globalLock.activeClients.writers</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The number of active client connections performing write operations.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::globalLock::currentQueue::readers</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.globalLock.currentQueue.readers</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::globalLock::currentQueue::total</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.globalLock.currentQueue.total</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::globalLock::currentQueue::writers</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.globalLock.currentQueue.writers</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::globalLock::lock time</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>1</multiplier>
                    <snmp_oid/>
                    <key>mongodb.globalLock.totalTime</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>s</units>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>0.001</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The time, in microseconds, since the database last started and created the globalLock. This is roughly equivalent to total server uptime.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::Hidden</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.hidden</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>3</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>Tells the user if the MongoDB is hidden, this means the database can write operations from other members, but won't server reads</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::ismaster status</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.ismaster</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap>
                        <name>MongoDB ismaster status</name>
                    </valuemap>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::memory::mappedWithJournal</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>1</multiplier>
                    <snmp_oid/>
                    <key>mongodb.memory.mappedWithJournal</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>B</units>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1048576</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>Only for the MMAPv1 storage engine.&#13;
&#13;
The amount of mapped memory, in megabytes (MB), including the memory used for journaling. This value will always be twice the value of mem.mapped. This field is only included if journaling is enabled.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::memory::virtual</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>1</multiplier>
                    <snmp_oid/>
                    <key>mongodb.memory.virtual</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>B</units>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1048576</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::network::bytesIn/s</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.network.bytesIn</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>B/s</units>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::network::bytesOut/s</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.network.bytesOut</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>B/s</units>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::network::request rate</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.network.numRequests</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::ok status</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.okstatus</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap>
                        <name>MongoDB ok status</name>
                    </valuemap>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::operation::command rate</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.operation.command</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>ops/s</units>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::operation::delete rate</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.operation.delete</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>ops/s</units>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::operation::getmore rate</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.operation.getmore</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>ops/s</units>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::operation::insert rate</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.operation.insert</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>ops/s</units>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::operation::query rate</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.operation.query</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>ops/s</units>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::operation::update rate</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.operation.update</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>ops/s</units>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::OplogLength</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.oplog</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>0</value_type>
                    <allowed_hosts/>
                    <units>s</units>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>Describes the number of seconds that exist in the Oplog</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::OplogSync</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.oplog-sync</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>0</value_type>
                    <allowed_hosts/>
                    <units>s</units>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>Shows the number of seconds between the last operation in the oplog, and the the current time. This should be fairly accurate on a database that has continuous operations, but if the database doesn't do anything it will fall behind.</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::page fault rate</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.page.faults</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>1</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::Priority</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.priority</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>0</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>The current priority of this database, 0 means it cannot be elected as master. This is used as part of the hiding process</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::storageEngine</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.storageEngine</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>0</trends>
                    <status>0</status>
                    <value_type>1</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::Wired Tiger Total Cache</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.total-cache</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>B</units>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::uptime</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.uptime</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>s</units>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::Wired Tiger Used Cache</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.used-cache</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>B</units>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::Wired Tiger Used Cache %</name>
                    <type>15</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.used-cache-p</key>
                    <delay>30</delay>
                    <history>90</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units>%</units>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params>(100 * last(mongodb.used-cache) / last(mongodb.total-cache))</params>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::version</name>
                    <type>2</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.version</key>
                    <delay>0</delay>
                    <history>28</history>
                    <trends>0</trends>
                    <status>0</status>
                    <value_type>1</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::zabbix sender</name>
                    <type>7</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>mongodb.zabbix.sender</key>
                    <delay>30</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>A script to send mongodb stats</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
                <item>
                    <name>MongoDB::number of process</name>
                    <type>7</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>proc.num[mongod]</key>
                    <delay>60</delay>
                    <history>28</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description/>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>MongoDB</name>
                        </application>
                    </applications>
                    <valuemap/>
                    <logtimefmt/>
                </item>
            </items>
            <discovery_rules>
                <discovery_rule>
                    <name>MongoDB discovery</name>
                    <type>2</type>
                    <snmp_community/>
                    <snmp_oid/>
                    <key>mongodb.discovery</key>
                    <delay>0</delay>
                    <status>0</status>
                    <allowed_hosts/>
                    <snmpv3_contextname/>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
                    <snmpv3_privpassphrase/>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <filter>
                        <evaltype>0</evaltype>
                        <formula/>
                        <conditions/>
                    </filter>
                    <lifetime>28</lifetime>
                    <description/>
                    <item_prototypes>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::average object size</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>0</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.avgObjSize[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units>B</units>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description>The average size of each document in bytes. This is the dataSize divided by the number of documents.</description>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap/>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::collection count</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>0</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.collections[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units/>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description>Contains a count of the number of collections in that database.</description>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap/>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::data size</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>0</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.dataSize[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units>B</units>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description>The total size in bytes of the uncompressed data held in this database. The scale argument affects this value. The dataSize will decrease when you remove documents.</description>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap/>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::file size</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>0</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.fileSize[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units>B</units>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description>The total size in bytes of the data files that hold the database. This value includes preallocated space and the padding factor. The value of fileSize only reflects the size of the data files for the database and not the namespace file.&#13;
&#13;
The scale argument affects this value. Only present when using the mmapv1 storage engine.</description>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap/>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::index count</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>0</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.indexes[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units/>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description>Contains a count of the total number of indexes across all collections in the database.</description>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap/>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::index size</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>0</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.indexSize[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units>B</units>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description>The total size in bytes of all indexes created on this database. The scale arguments affects this value.</description>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap/>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::namespace size</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>1</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.nsSizeMB[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units>B</units>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1048576</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description>The total size of the namespace files (i.e. that end with .ns) for this database. You cannot change the size of the namespace file after creating a database, but you can change the default size for all new namespace files with the nsSize runtime option.&#13;
&#13;
Only present when using the mmapv1 storage engine.</description>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap/>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::extent count</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>0</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.numExtents[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units/>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description>Contains a count of the number of extents in the database across all collections.</description>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap/>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::object count</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>0</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.objects[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units/>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description>Contains a count of the number of objects (i.e. documents) in the database across all collections.</description>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap/>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::ok status</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>0</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.ok[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units/>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description/>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap>
                                <name>MongoDB ok status</name>
                            </valuemap>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                        <item_prototype>
                            <name>MongoDB::{#MONGODBNAME}::storage size</name>
                            <type>2</type>
                            <snmp_community/>
                            <multiplier>0</multiplier>
                            <snmp_oid/>
                            <key>mongodb.stats.storageSize[{#MONGODBNAME}]</key>
                            <delay>0</delay>
                            <history>28</history>
                            <trends>365</trends>
                            <status>0</status>
                            <value_type>3</value_type>
                            <allowed_hosts/>
                            <units>B</units>
                            <delta>0</delta>
                            <snmpv3_contextname/>
                            <snmpv3_securityname/>
                            <snmpv3_securitylevel>0</snmpv3_securitylevel>
                            <snmpv3_authprotocol>0</snmpv3_authprotocol>
                            <snmpv3_authpassphrase/>
                            <snmpv3_privprotocol>0</snmpv3_privprotocol>
                            <snmpv3_privpassphrase/>
                            <formula>1</formula>
                            <delay_flex/>
                            <params/>
                            <ipmi_sensor/>
                            <data_type>0</data_type>
                            <authtype>0</authtype>
                            <username/>
                            <password/>
                            <publickey/>
                            <privatekey/>
                            <port/>
                            <description>The total amount of space in bytes allocated to collections in this database for document storage. The scale argument affects this value. The storageSize does not decrease as you remove or shrink documents. This value may be smaller than dataSize for databases using the WiredTiger storage engine with compression enabled.</description>
                            <inventory_link>0</inventory_link>
                            <applications>
                                <application>
                                    <name>MongoDB</name>
                                </application>
                            </applications>
                            <valuemap/>
                            <logtimefmt/>
                            <application_prototypes/>
                        </item_prototype>
                    </item_prototypes>
                    <trigger_prototypes>
                        <trigger_prototype>
                            <expression>{Template MongoDB:mongodb.stats.ok[{#MONGODBNAME}].count(#3,0)}=3</expression>
                            <recovery_mode>0</recovery_mode>
                            <recovery_expression/>
                            <name>MongoDB::{#MONGODBNAME} is not OK</name>
                            <correlation_mode>0</correlation_mode>
                            <correlation_tag/>
                            <url/>
                            <status>0</status>
                            <priority>3</priority>
                            <description/>
                            <type>0</type>
                            <manual_close>0</manual_close>
                            <dependencies/>
                            <tags/>
                        </trigger_prototype>
                    </trigger_prototypes>
                    <graph_prototypes>
                        <graph_prototype>
                            <name>{#MONGODBNAME}::collection and extent count</name>
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
                                    <calc_fnc>7</calc_fnc>
                                    <type>0</type>
                                    <item>
                                        <host>Template MongoDB</host>
                                        <key>mongodb.stats.collections[{#MONGODBNAME}]</key>
                                    </item>
                                </graph_item>
                                <graph_item>
                                    <sortorder>1</sortorder>
                                    <drawtype>0</drawtype>
                                    <color>F63100</color>
                                    <yaxisside>0</yaxisside>
                                    <calc_fnc>7</calc_fnc>
                                    <type>0</type>
                                    <item>
                                        <host>Template MongoDB</host>
                                        <key>mongodb.stats.numExtents[{#MONGODBNAME}]</key>
                                    </item>
                                </graph_item>
                            </graph_items>
                        </graph_prototype>
                        <graph_prototype>
                            <name>{#MONGODBNAME}::db size</name>
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
                                    <calc_fnc>7</calc_fnc>
                                    <type>0</type>
                                    <item>
                                        <host>Template MongoDB</host>
                                        <key>mongodb.stats.dataSize[{#MONGODBNAME}]</key>
                                    </item>
                                </graph_item>
                                <graph_item>
                                    <sortorder>1</sortorder>
                                    <drawtype>0</drawtype>
                                    <color>F63100</color>
                                    <yaxisside>0</yaxisside>
                                    <calc_fnc>7</calc_fnc>
                                    <type>0</type>
                                    <item>
                                        <host>Template MongoDB</host>
                                        <key>mongodb.stats.fileSize[{#MONGODBNAME}]</key>
                                    </item>
                                </graph_item>
                                <graph_item>
                                    <sortorder>2</sortorder>
                                    <drawtype>0</drawtype>
                                    <color>2774A4</color>
                                    <yaxisside>0</yaxisside>
                                    <calc_fnc>7</calc_fnc>
                                    <type>0</type>
                                    <item>
                                        <host>Template MongoDB</host>
                                        <key>mongodb.stats.nsSizeMB[{#MONGODBNAME}]</key>
                                    </item>
                                </graph_item>
                                <graph_item>
                                    <sortorder>3</sortorder>
                                    <drawtype>0</drawtype>
                                    <color>EE00EE</color>
                                    <yaxisside>0</yaxisside>
                                    <calc_fnc>7</calc_fnc>
                                    <type>0</type>
                                    <item>
                                        <host>Template MongoDB</host>
                                        <key>mongodb.stats.storageSize[{#MONGODBNAME}]</key>
                                    </item>
                                </graph_item>
                            </graph_items>
                        </graph_prototype>
                        <graph_prototype>
                            <name>{#MONGODBNAME}::indexes stats</name>
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
                                    <yaxisside>1</yaxisside>
                                    <calc_fnc>7</calc_fnc>
                                    <type>0</type>
                                    <item>
                                        <host>Template MongoDB</host>
                                        <key>mongodb.stats.indexSize[{#MONGODBNAME}]</key>
                                    </item>
                                </graph_item>
                                <graph_item>
                                    <sortorder>1</sortorder>
                                    <drawtype>0</drawtype>
                                    <color>F63100</color>
                                    <yaxisside>0</yaxisside>
                                    <calc_fnc>7</calc_fnc>
                                    <type>0</type>
                                    <item>
                                        <host>Template MongoDB</host>
                                        <key>mongodb.stats.indexes[{#MONGODBNAME}]</key>
                                    </item>
                                </graph_item>
                            </graph_items>
                        </graph_prototype>
                        <graph_prototype>
                            <name>{#MONGODBNAME}::objects stats</name>
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
                                    <yaxisside>1</yaxisside>
                                    <calc_fnc>7</calc_fnc>
                                    <type>0</type>
                                    <item>
                                        <host>Template MongoDB</host>
                                        <key>mongodb.stats.avgObjSize[{#MONGODBNAME}]</key>
                                    </item>
                                </graph_item>
                                <graph_item>
                                    <sortorder>1</sortorder>
                                    <drawtype>0</drawtype>
                                    <color>F63100</color>
                                    <yaxisside>0</yaxisside>
                                    <calc_fnc>7</calc_fnc>
                                    <type>0</type>
                                    <item>
                                        <host>Template MongoDB</host>
                                        <key>mongodb.stats.objects[{#MONGODBNAME}]</key>
                                    </item>
                                </graph_item>
                            </graph_items>
                        </graph_prototype>
                    </graph_prototypes>
                    <host_prototypes/>
                </discovery_rule>
            </discovery_rules>
            <httptests/>
            <macros>
                <macro>
                    <macro>{$PAGE_FAULT_TH_WARN}</macro>
                    <value>1</value>
                </macro>
            </macros>
            <templates/>
            <screens>
                <screen>
                    <name>MongoDB::db stats</name>
                    <hsize>1</hsize>
                    <vsize>4</vsize>
                    <screen_items>
                        <screen_item>
                            <resourcetype>20</resourcetype>
                            <width>400</width>
                            <height>80</height>
                            <x>0</x>
                            <y>0</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>{#MONGODBNAME}::db size</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                        <screen_item>
                            <resourcetype>20</resourcetype>
                            <width>400</width>
                            <height>80</height>
                            <x>0</x>
                            <y>1</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>{#MONGODBNAME}::indexes stats</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                        <screen_item>
                            <resourcetype>20</resourcetype>
                            <width>400</width>
                            <height>80</height>
                            <x>0</x>
                            <y>2</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>{#MONGODBNAME}::objects stats</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                        <screen_item>
                            <resourcetype>20</resourcetype>
                            <width>400</width>
                            <height>80</height>
                            <x>0</x>
                            <y>3</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>{#MONGODBNAME}::collection and extent count</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                    </screen_items>
                </screen>
                <screen>
                    <name>MongoDB::server status</name>
                    <hsize>2</hsize>
                    <vsize>4</vsize>
                    <screen_items>
                        <screen_item>
                            <resourcetype>0</resourcetype>
                            <width>500</width>
                            <height>100</height>
                            <x>0</x>
                            <y>0</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>MongoDB::connections</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                        <screen_item>
                            <resourcetype>0</resourcetype>
                            <width>500</width>
                            <height>100</height>
                            <x>1</x>
                            <y>0</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>MongoDB::memory</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                        <screen_item>
                            <resourcetype>0</resourcetype>
                            <width>500</width>
                            <height>100</height>
                            <x>0</x>
                            <y>1</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>MongoDB::network</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                        <screen_item>
                            <resourcetype>0</resourcetype>
                            <width>500</width>
                            <height>100</height>
                            <x>1</x>
                            <y>1</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>MongoDB::page faults</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                        <screen_item>
                            <resourcetype>0</resourcetype>
                            <width>500</width>
                            <height>100</height>
                            <x>0</x>
                            <y>2</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>MongoDB::operations</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                        <screen_item>
                            <resourcetype>0</resourcetype>
                            <width>500</width>
                            <height>100</height>
                            <x>0</x>
                            <y>3</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>MongoDB::global lock::current queue</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                        <screen_item>
                            <resourcetype>0</resourcetype>
                            <width>500</width>
                            <height>100</height>
                            <x>1</x>
                            <y>3</y>
                            <colspan>1</colspan>
                            <rowspan>1</rowspan>
                            <elements>0</elements>
                            <valign>0</valign>
                            <halign>0</halign>
                            <style>0</style>
                            <url/>
                            <dynamic>0</dynamic>
                            <sort_triggers>0</sort_triggers>
                            <resource>
                                <name>MongoDB::global lock::active clients</name>
                                <host>Template MongoDB</host>
                            </resource>
                            <max_columns>3</max_columns>
                            <application/>
                        </screen_item>
                    </screen_items>
                </screen>
            </screens>
        </template>
    </templates>
    <triggers>
        <trigger>
            <expression>{Template MongoDB:mongodb.fsync-locked.last()}=1 &#13;
and {Template MongoDB:mongodb.hidden.last()}=1 &#13;
and {Template MongoDB:mongodb.priority.last()}=0</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>Locked, hidden and priority 0 on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>2</priority>
            <description>The database is locked, hidden and priority set to 0</description>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.fsync-locked.last()}=1 &#13;
and {Template MongoDB:mongodb.hidden.last()}=1 &#13;
and {Template MongoDB:mongodb.priority.last()}=1</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>Locked, hidden and priority 1 on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>4</priority>
            <description>The database is locked, hidden and priority set to 1</description>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.fsync-locked.last()}=1 &#13;
and {Template MongoDB:mongodb.hidden.last()}=0&#13;
and {Template MongoDB:mongodb.priority.last()}=0</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>Locked, not hidden and priority 0 on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>4</priority>
            <description>The database is locked, hidden and priority set to 0</description>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.fsync-locked.last()}=1 &#13;
and {Template MongoDB:mongodb.hidden.last()}=0&#13;
and {Template MongoDB:mongodb.priority.last()}=1</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>Locked, not hidden and priority 1 on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>4</priority>
            <description>The database is locked, not hidden and priority set to 1</description>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.oplog.last()}&lt;259200</expression>
            <recovery_mode>1</recovery_mode>
            <recovery_expression>{Template MongoDB:mongodb.oplog.last()}&gt;259320</recovery_expression>
            <name>MongoDB Oplog length 3 days on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>4</priority>
            <description/>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.oplog.last()}&lt;604800 and not {Template MongoDB:mongodb.oplog.last()}&lt;259200</expression>
            <recovery_mode>1</recovery_mode>
            <recovery_expression>{Template MongoDB:mongodb.oplog.last()}&gt;604920</recovery_expression>
            <name>MongoDB Oplog length 7 days on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>2</priority>
            <description/>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.oplog-sync.last()}&gt;=60 and not {Template MongoDB:mongodb.oplog-sync.last()}&gt;=300</expression>
            <recovery_mode>1</recovery_mode>
            <recovery_expression>{Template MongoDB:mongodb.oplog-sync.last()}&lt;30</recovery_expression>
            <name>MongoDB Oplog Sync 1 minute on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>2</priority>
            <description/>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.oplog-sync.last()}&gt;=300</expression>
            <recovery_mode>1</recovery_mode>
            <recovery_expression>{Template MongoDB:mongodb.oplog-sync.last()}&lt;240</recovery_expression>
            <name>MongoDB Oplog Sync 5 minute on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>4</priority>
            <description/>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:proc.num[mongod].count(#3,0)}=3</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>MongoDB process is not running on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>4</priority>
            <description/>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.okstatus.count(#3,0)}=3</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>MongoDB server status is not OK</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>3</priority>
            <description/>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.used-cache-p.last()}&gt;=90 and {Template MongoDB:mongodb.used-cache-p.last()}&lt;95</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>MongoDB Wired Tiger Used cache 90% on  {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>2</priority>
            <description/>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.used-cache-p.last()}&gt;=95</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>MongoDB Wired Tiger Used cache 95% on  {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>4</priority>
            <description/>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.fsync-locked.last()}=0&#13;
and {Template MongoDB:mongodb.hidden.last()}=1 &#13;
and {Template MongoDB:mongodb.priority.last()}=0</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>Not locked, but is hidden and priority 0 on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>2</priority>
            <description>The database is not locked, but is hidden and priority set to 0</description>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.fsync-locked.last()}=0&#13;
and {Template MongoDB:mongodb.hidden.last()}=1 &#13;
and {Template MongoDB:mongodb.priority.last()}=1</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>Not locked, is hidden and priority 1 on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>4</priority>
            <description>The database is not locked, is hidden and priority set to 1</description>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.fsync-locked.last()}=0 &#13;
and {Template MongoDB:mongodb.hidden.last()}=0&#13;
and {Template MongoDB:mongodb.priority.last()}=0</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>Not locked or hidden, but priority 0 on {HOST.NAME}</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>2</priority>
            <description>The database is not locked or hidden, but priority set to 0</description>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
        <trigger>
            <expression>{Template MongoDB:mongodb.page.faults.min(#3)}&gt;{$PAGE_FAULT_TH_WARN}</expression>
            <recovery_mode>0</recovery_mode>
            <recovery_expression/>
            <name>Page faults detected on {HOST.NAME} (LV={ITEM.VALUE})</name>
            <correlation_mode>0</correlation_mode>
            <correlation_tag/>
            <url/>
            <status>0</status>
            <priority>2</priority>
            <description/>
            <type>0</type>
            <manual_close>0</manual_close>
            <dependencies/>
            <tags/>
        </trigger>
    </triggers>
    <graphs>
        <graph>
            <name>MongoDB::asserts</name>
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
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.asserts.msg</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>1</sortorder>
                    <drawtype>0</drawtype>
                    <color>F63100</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.asserts.regular</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>2</sortorder>
                    <drawtype>0</drawtype>
                    <color>2774A4</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.asserts.rollovers</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>3</sortorder>
                    <drawtype>0</drawtype>
                    <color>A54F10</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.asserts.user</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>4</sortorder>
                    <drawtype>0</drawtype>
                    <color>FC6EA3</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.asserts.warning</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
        <graph>
            <name>MongoDB::connections</name>
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
                    <drawtype>4</drawtype>
                    <color>1A7C11</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.connection.available</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>1</sortorder>
                    <drawtype>5</drawtype>
                    <color>F63100</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.connection.current</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
        <graph>
            <name>MongoDB::global lock::active clients</name>
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
                    <color>F63100</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.globalLock.activeClients.total</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>1</sortorder>
                    <drawtype>0</drawtype>
                    <color>1A7C11</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.globalLock.activeClients.readers</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>2</sortorder>
                    <drawtype>0</drawtype>
                    <color>2774A4</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.globalLock.activeClients.writers</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
        <graph>
            <name>MongoDB::global lock::current queue</name>
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
                    <color>F63100</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.globalLock.currentQueue.total</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>1</sortorder>
                    <drawtype>0</drawtype>
                    <color>1A7C11</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.globalLock.currentQueue.readers</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>2</sortorder>
                    <drawtype>0</drawtype>
                    <color>2774A4</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.globalLock.currentQueue.writers</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
        <graph>
            <name>MongoDB::memory</name>
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
                    <color>2774A4</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.memory.virtual</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>1</sortorder>
                    <drawtype>0</drawtype>
                    <color>FC6EA3</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.memory.mappedWithJournal</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>2</sortorder>
                    <drawtype>0</drawtype>
                    <color>1A7C11</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.used-cache</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
        <graph>
            <name>MongoDB::network</name>
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
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.network.bytesIn</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>1</sortorder>
                    <drawtype>0</drawtype>
                    <color>F63100</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.network.bytesOut</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>2</sortorder>
                    <drawtype>0</drawtype>
                    <color>2774A4</color>
                    <yaxisside>1</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.network.numRequests</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
        <graph>
            <name>MongoDB::operations</name>
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
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.operation.command</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>1</sortorder>
                    <drawtype>0</drawtype>
                    <color>F63100</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.operation.delete</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>2</sortorder>
                    <drawtype>0</drawtype>
                    <color>2774A4</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.operation.getmore</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>3</sortorder>
                    <drawtype>0</drawtype>
                    <color>A54F10</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.operation.insert</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>4</sortorder>
                    <drawtype>0</drawtype>
                    <color>FC6EA3</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.operation.query</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>5</sortorder>
                    <drawtype>0</drawtype>
                    <color>6C59DC</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.operation.update</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
        <graph>
            <name>MongoDB::OplogLength</name>
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
                        <host>Template MongoDB</host>
                        <key>mongodb.oplog</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
        <graph>
            <name>MongoDB::OplogSync</name>
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
                        <host>Template MongoDB</host>
                        <key>mongodb.oplog-sync</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
        <graph>
            <name>MongoDB::page faults</name>
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
                    <color>DD0000</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>7</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.page.faults</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
        <graph>
            <name>Wired Tiger Memory Usage</name>
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
                        <host>Template MongoDB</host>
                        <key>mongodb.total-cache</key>
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
                        <host>Template MongoDB</host>
                        <key>mongodb.used-cache</key>
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
                        <host>Template MongoDB</host>
                        <key>mongodb.dirty-cache</key>
                    </item>
                </graph_item>
                <graph_item>
                    <sortorder>3</sortorder>
                    <drawtype>0</drawtype>
                    <color>A54F10</color>
                    <yaxisside>1</yaxisside>
                    <calc_fnc>2</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Template MongoDB</host>
                        <key>mongodb.used-cache-p</key>
                    </item>
                </graph_item>
            </graph_items>
        </graph>
    </graphs>
    <value_maps>
        <value_map>
            <name>MongoDB ismaster status</name>
            <mappings>
                <mapping>
                    <value>0</value>
                    <newvalue>False</newvalue>
                </mapping>
                <mapping>
                    <value>1</value>
                    <newvalue>True</newvalue>
                </mapping>
            </mappings>
        </value_map>
        <value_map>
            <name>MongoDB ok status</name>
            <mappings>
                <mapping>
                    <value>0</value>
                    <newvalue>False</newvalue>
                </mapping>
                <mapping>
                    <value>1</value>
                    <newvalue>True</newvalue>
                </mapping>
            </mappings>
        </value_map>
    </value_maps>
</zabbix_export>
```

### 5.1 导入模板
配置-》模板-》导入
![image.png](https://img.hacpai.com/file/2020/04/image-866ec9f7.png)

选择`Template_MongoDB.xml`导入即可
![image.png](https://img.hacpai.com/file/2020/04/image-bb2fab6b.png)

## 6.主机添加mongodb检测模块
配置-》主机-》选择主机
![image.png](https://img.hacpai.com/file/2020/04/image-c90f9909.png)

模板-》选择
![image.png](https://img.hacpai.com/file/2020/04/image-aa6d4d51.png)

勾选`Template MongoDB`，点击更新
![image.png](https://img.hacpai.com/file/2020/04/image-3119eddb.png)


## 7.验证
检测-》最新数据-》应用集选择mongodb，点击应用
![image.png](https://img.hacpai.com/file/2020/04/image-d41b0df1.png)

检测-》图形-》选择mongodb相关内容
![image.png](https://img.hacpai.com/file/2020/04/image-c383439d.png)

## 8.最终效果
![image.png](https://img.hacpai.com/file/2020/04/image-cac95e30.png)
