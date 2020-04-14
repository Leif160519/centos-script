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
