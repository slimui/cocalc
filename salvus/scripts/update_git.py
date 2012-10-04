#!/usr/bin/env python

import hosts, os, socket, sys

sys.path.append("%s/salvus/salvus/"%os.environ['HOME'])

user = os.environ['USER']

import misc

for hostname in hosts.persistent_hosts:
    # the u below means that this won't overwrite newer files on destination, which could happen by accident if we were careless.
    ip = misc.local_ip_address(hostname)
    if ip.startswith('127'): continue
    cmd = 'ssh salvus@%s "cd salvus; git pull %s@%s:salvus/"'%(hostname, user, ip)
    print cmd
    os.system(cmd)

print "Deal with these manually: ", hosts.unsafe_hosts
