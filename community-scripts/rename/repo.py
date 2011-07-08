import os
import stat
import subprocess
import md5
import time
import exceptions

indexdir="/mnt/gluster/testdir/"
inputdirs=[
           "/mnt/gluster/input1/",
           "/mnt/gluster/input2/",
           "/mnt/gluster/input3/",
           "/mnt/gluster/input4/",
           "/mnt/gluster/input5/"]

def getstat(filepath):
    return os.stat(filepath)

def getmd5sum(path):
    f = open(path,'rb')
    m = md5.new()
    while True:  
       data = f.read(8096)
       if(not data):
          break
       m.update(data)
    f.close()
    return m.hexdigest()

def listdir(path):
    
    cmd = "ls -rt " + path
    filelist = [] 
    process = subprocess.Popen(cmd, shell=True,stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    
    for line in process.stdout:
        #print line
        line = str(line).rstrip()
        filelist.append(path + str(line))       
   
    output,error = process.communicate()
    #print output
    return filelist


def writeindex(indexfilepath,map):
    
    tempfile = indexfilepath + ".tmp"
    fd = open(tempfile, 'w')
    for fname in map.keys():
        lst = map[fname]
        print >> fd , '%s %s' % (lst[0], lst[1])

    fd.flush()
    fd.close()
    os.rename(tempfile, indexfilepath)

def loadindex(indexfilepath):
    try:
        f = open(indexfilepath,'r')
        lst = []
        for line in f:
                lst.append(line)
        f.close() 
    except Exception,e:
        print e,indexfilepath 

while(True):

        for dir in inputdirs:
            map = {}
            ret = listdir(dir)
            fname = dir.split("/")[-2]
            idxname = fname + ".idx"
            print "dir = " + str(dir)
            for x in ret:
                sts = getstat(x)
                m5 = getmd5sum(x)
                lst = [m5,sts] 
                map[x] = lst
            if os.path.exists(indexdir + "/" + idxname):
               loadindex(indexdir + "/" + idxname)
            writeindex(indexdir + "/" + idxname,map) 
        
        met = listdir(indexdir)
        for z in met:
            loadindex(z)
        mapx={}
        metname = indexdir + "/meta.idx"
        for y in met:
              sts = getstat(y)
              m5 = getmd5sum(y)
              lst = [m5,sts]
              mapx[y] = lst          
        writeindex(metname,mapx)

        print "sleeping for 60 secs"
        time.sleep(10)

#listdir(inputdirs[0])



