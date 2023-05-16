#!/usr/bin/env python
import os
import simplejson as json
t=os.popen("""sudo docker ps |grep -v 'CONTAINER ID'|awk {'print $NF'} """)
container_name = []
for container in  t.readlines():
        r = os.path.basename(container.strip())
        container_name += [{'{#CONTAINERNAME}':r}]
print json.dumps({'data':container_name},sort_keys=True,indent=4,separators=(',',':'))
