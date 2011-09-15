#!/usr/bin/env python

import os, sys, tempfile, select, time

def connect(vol, sleeptime=None):
    d = tempfile.mkdtemp()
    try:
        argv = ["glusterfs", "-LDEBUG", "-l/tmp/gl0.log", '-s', "localhost", 
                 '--volfile-id', vol, '--client-pid=-1', d]
        if os.spawnvp(os.P_WAIT, argv[0], argv):
            raise RuntimeError("command failed: " + " ".join(argv))
        print >> sys.stderr, 'auxiliary glusterfs mount in place'
        os.chdir(d)
        argv = ['umount', '-l', d]
        if sleeptime != None:
        	time.sleep(sleeptime)
        if os.spawnvp(os.P_WAIT, argv[0], argv):
            raise RuntimeError("command failed: " + " ".join(argv))
    finally:
        try:
            os.rmdir(d)
        except:
            print >> sys.stderr, 'stale mount possibly left behind on ' + d
    print >> sys.stderr, 'auxiliary glusterfs mount prepared'

args = sys.argv[1:2]
if len(sys.argv) > 2:
    args.append(float(sys.argv[2])) 
connect(*args)
