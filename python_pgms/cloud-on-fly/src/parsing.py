#!/usr/bin/python
# Filename: parsing.py

# This script is used to take input from the user to setup a storage cluster. It takes cluster translator(afr|dht|stripe) as the mandatory input. Without the clustering translator it cannot proceed. The other arguments are set to some default values, such as number of servers, number of clients etc. User can give his own options 

import getopt, sys, os, string
from optparse import OptionParser,OptionGroup,make_option
#from server_manager import *


num_replica = 2
name = "cluster"
clients = 1
version = "latest_git"
#num_servers = 4
total_servers = 4
num_stripe = 4
#num_servers = ''
default_port = 6996
port_min = 1024

def get_commandline_arguments():

    usage_str = "%prog: -t <CLUSTER_TYPE>  [-n <CLUSTER_NAME>] [-s <NUM_OF_SERVERS>] [-c <NUM_OF_CLIENTS>] [-v <VERSION>]"
    desc_str = "Takes the arguments from user and builds a cluster specified by the user in the command"
    
    parser = OptionParser(usage=usage_str, description=desc_str)
    
    #parse.add_option_group(group)
    #(options, args) = parse.parse_args()

# Basic option list
    group = OptionGroup(parser, "Basic Options")

    group.add_option("-t", "--type", dest="cluster_type",
                 help="<cluster-type afr|dht|stripe>")
    group.add_option("-n", "--name", dest="cluster_name",
                 default="cluster", help="clustername default:cluster appended with the number of the cluster being created")
    group.add_option("-s", "--servers", dest="num_servers",
                 type="int", help="number of servers. default: 2 if afr and 4 if stripe and for dht available machines")
    group.add_option("-c", "--clients", dest="num_clients",
                 type="int", help="number of clients")
    group.add_option("-p", "--port", dest="port",
                 type="int", help="port number to connect to")
    group.add_option("-v", "--version", dest="version",
                 default="master", help="version of the glusterfs to be used. default:master, i.e. latest git pulled glusterfs")
    

    parser.add_option_group(group)
    (options, args) = parser.parse_args()

    if options.cluster_type is None:
        print "Error: Cluster type is mandatory. Please provide a cluster type (afr|dht|stripe)"
        print usage_str
        #raise ValueError
        sys.exit(2)

    elif str(options.cluster_type) == "afr":
        print('You have asked for mirroring cluster')
        
    elif str(options.cluster_type) == "stripe":
        print('You have asked for a stripe cluster')
        
    elif str(options.cluster_type) == "dht":
        print('You have asked for a distributed cluster')
        

    else:
        print "Invalid cluster type . Please provide a valid cluster type (afr|dht|stripe)"
        #raise ValueError
        sys.exit(2)
    
    if options.cluster_name is None:
        cluster_name = "dev"
        
    if options.num_servers is not None:
        if str(options.cluster_type) == "afr":
            if (options.num_servers % num_replica) != 0:
                print "Error: AFR takes only multiples of 2 servers. Please provide valid number of servers"
               # raise ValueError
                sys.exit(2)
            else:
                #num_replica = options.num_servers
                print 'AFR: Number of servers provoded is valid'
        elif str(options.cluster_type) == "stripe":
            if (options.num_servers % num_stripe) != 0:
                print "Error: stripe takes multiple of 4 servers. Please provide valid numner of servers"
                #raise ValueError
                sys.exit(2)
            else:
                #num_stripe = options.num_servers
                print 'stripe: Number of servers provided is valid'
        elif str(options.cluster_type) == "dht":
            print('Distributing the files across', options.num_servers, 'volumes')
    else:
        print "Number of servers is kept as default"
        print options.num_servers
        options.num_servers = total_servers
            
    if options.num_clients is None:
        options.num_clients = clients
        
    if options.port is None:
        options.port = default_port
    elif options.port < port_min:
        print 'Error:port number should be greater than', port_min
        sys.exit(2)

    if options.version is None:
        print "No version number provoded. Hence continuing with the default version(latest)."
        options.version = version
    else:
        print "Building the storage cluster with glusterfs version", options.version 

    print 'The options provided are:\ncluster type:', options.cluster_type, 'Cluster name:', options.cluster_name, 'Number of servers:', options.num_servers, 'Number of clients:', options.num_clients, 'Port Number:', options.port, 'Version:', options.version



def main():
    try:
        get_commandline_arguments()
    except:
        ValueError
    
main()
    
