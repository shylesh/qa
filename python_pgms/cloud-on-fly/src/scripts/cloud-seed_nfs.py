#!/usr/bin/env python
# - coding: utf-8 -*-
import getopt, sys, os, string,glob
from optparse import OptionParser,OptionGroup,make_option

default=1
##vol_files=None 
nfs="on"
overflow=False
#dbpath="/home/lakshmipathi/cloud_db.sqlite"
dbpath="/usr/share/cloud/cloud_db.sqlite"
opt_mount_path="/usr/share/cloud/mount_opt.sh"
cmd_pdsh ="/usr/local/bin/pdsh  -R exec -w "
#cmd_pdsh ="/opt/pdsh-2.18/bin/pdsh  -R exec -w "
cmd_pdsh2=" ssh -x -l %u %h "

cmd_mkdir = "/bin/mkdir -p "
cmd_kaput = "kaput -n "


cmd_cat = "/bin/cat "
cmd_mount = "/bin/mount "
cmd_umount = "/bin/umount "
cmd_mv = "/bin/mv "
cmd_kill="/bin/kill -9 "
cmd_rm="/bin/rm -rf "
cmd_cp="cp "


cmd_pid1="ps -p "
cmd_pid2=" -o comm="


cloud_seed_trash=" /tmp/.cloud_seed_trash"
glusterfs_version="gnfs-git" # default gluster version
pdsh_user="root@"

#base of client mont pts
cloud_dir="/mnt/export/gluster/cloud/mnt/"
#cloud_export_dir="/home/lakshmipathi/mnt/export/"
#cloud_spec_dir="/home/lakshmipathi/mnt/specs_dir/"

cloud_export_dir="/ebs-raid/export/gluster/cloud/export/"
cloud_spec_dir="/ebs-raid/export/gluster/cloud/specs_dir/"


#SQL Stmts
SQL_STMT_INIT_CLOUD = "insert into cloud_seed (cloud_id,cloud_name,status,version) values (?,?,?,?)"
SQL_STMT_ACTIVATE_CLOUD ="update cloud_seed set status='active',type=?  where cloud_id=?"
#SQL_STMT_DEACTIVATE_CLOUD="update cloud_seed set status='free' where cloud_id=?"

SQL_STMT_DEACTIVATE_CLOUD="delete from  cloud_seed where cloud_id=?"


SQL_STMT_GET_S_MAX="select max(rowid) from server_pool"
SQL_STMT_GET_C_MAX="select max(rowid) from client_pool"

SQL_STMT_GET_S_POOL="select * from server_pool limit (?)"
SQL_STMT_GET_C_POOL="select * from client_pool limit (?)"

SQL_STMT_INSERT_S_PROCESS="insert into server_process(server,status,cloud_id,snum) values (?,?,?,?)"
SQL_STMT_INSERT_C_PROCESS="insert into client_process(client,status,cloud_id,cnum) values (?,?,?,?)"

SQL_STMT_S_PROCESS_GETBY_CLOUDID="select * from server_process where cloud_id=?"
SQL_STMT_C_PROCESS_GETBY_CLOUDID="select * from client_process where cloud_id=?"

SQL_STMT_S_PROCESS_GETBY_CLOUDID2="select * from server_process where status='running' and cloud_id=? "
SQL_STMT_C_PROCESS_GETBY_CLOUDID2="select * from client_process where status='running' and cloud_id=? "




SQL_STMT_UPDATE_S_PROCESS="update server_process set export_dir =? where cloud_id=? and snum=? and server=?"
SQL_STMT_UPDATE_C_PROCESS="update client_process set mount_pt =? where cloud_id=? and cnum=? and client=?"

SQL_STMT_UPDATEPID_S_PROCESS="update server_process set server_pid =?,logfile=?,status='running' where cloud_id=? and snum=? and server=?"
SQL_STMT_UPDATEPID_C_PROCESS="update client_process set client_pid =?,logfile=?,status='running' where cloud_id=? and cnum=? and client=?"

SQL_STMT_UPDATE_DEFPORT_S_PROCESS="update server_process set port=? where cloud_id=?"
SQL_STMT_UPDATEPORT_S_PROCESS="update server_process set port =? where cloud_id=? and snum=? and server=?"
#cloud stop queries 
SQL_STMT_CHECK_CLOUD = "select status,type,cloud_id,version from cloud_seed where cloud_name=?"
#SQL_STMT_UPDATESTATUS_C_PROCESS="update client_process set status='not_running' where cloud_id=?"
#SQL_STMT_UPDATESTATUS_S_PROCESS="update server_process set status='not_running' where cloud_id=?"

SQL_STMT_UPDATESTATUS_C_PROCESS="delete from client_process  where cloud_id=?"
SQL_STMT_UPDATESTATUS_S_PROCESS="delete from server_process  where cloud_id=?"

SQL_STMT_CHECKALL_CLOUD = "select cloud_id,type,cloud_name,version from cloud_seed where status='active'"
#update status 
SQL_STMT_CSTATUS_CHECK_UPDATE="update client_process set status='not-running' where cloud_id=? and cnum=? and client=?"
SQL_STMT_SSTATUS_CHECK_UPDATE="update server_process set status='not-running' where cloud_id=? and snum=? and server=?"


import os
import sqlite3
import time
import sys
import fileinput

#Logging 

log_file =  open("/var/log/cloud.log","a")
def logging_start():
	global log_file
	log_file = open("/var/log/cloud.log","a")

	old_stdout = sys.stdout
	sys.stdout = log_file
	print time.asctime( time.localtime(time.time()) )
	return old_stdout

def logging_stop(old_stdout):
	sys.stdout = old_stdout
	log_file.close()


class Cloud_db:
	db=None
	cursor=None
	i=5
	cloud_id=1000
	server_pool_max=0
	client_pool_max=0
	#create a empty list
	server_pool_list=[]
	client_pool_list=[]
	#create a empty list
	server_process_list=[]
	client_process_list=[]
	# get from table and put  values in dict
	server_dict={}
	exportdir_dict={}
	client_dict={}
	mntpt_dict={}

	dummy_server_files=[]
	def __init__(self):
		self.db=None
		self.cursor=None
		self.server_pool_list=[]
		self.client_pool_list=[]	
		self.server_process_list=[]
		self.client_process_list=[]
		self.dummy_server_files=[]
		self.server_dict={}
		self.exportdir_dict={}
		# put  values in dict from process_table
		self.client_dict={}
		self.mntpt_dict={}

		self.cloud_id=1000
		self.server_pool_max=0
		self.client_pool_max=0

                self.num_servers=4
                self.num_clients=1
                self.port=6196
		self.glusterfs_version=glusterfs_version
		self.default_glusterfs_path="/opt/glusterfs/"+self.glusterfs_version
		self.cmd_glfs_start=self.default_glusterfs_path+"/sbin/glusterfsd -f "

		self.run_file = " "
                #################
                num_replica = 2
                name = "cluster"
                clients = 1
                version = "latest_git"
                #num_servers = 4
                total_servers_stripe = 4
		total_servers_afr=2
		total_servers_dht=2
                num_stripe = 4
                #num_servers = ''
                default_port = 6196
                port_min = 1024


                usage_str1="To start: cloud-seed.py --start <CLUSTER_TYPE> --name <CLUSTER_NAME> [-s <NUM_OF_SERVERS>][-c <NUM_OF_CLIENTS>][-v <VERSION>][-p <PORT>]"
                usage_str2="To stop cluster           : cloud-seed.py --stop <CLOUD_ID>"
		usage_str3="To display cluster status : cloud-seed.py --status <CLOUD_ID>"
		usage_str4="To display all clusters   : cloud-seed.py --show all "
		usage_str5="To run commands on client : cloud-seed.py --run <CLOUD_SCRIPT> --name <CLUSTER_NAME>"

		usage_str="\n"+usage_str1+"\n\n"+usage_str2+"\n\n"+usage_str3+"\n\n"+usage_str4+"\n\n"+usage_str5
				
                desc_str = "Takes the arguments from user and builds a cluster specified by the user in the command"
                
                parser = OptionParser(usage=usage_str, description=desc_str)
                
                #parse.add_option_group(group)
                #(options, args) = parse.parse_args()

                # Basic option list
                group = OptionGroup(parser, "Basic Options")

                group.add_option("-t", "--start", dest="cluster_type",
                                                                 help="<cluster-type afr|dht|stripe>")
                group.add_option("-n", "--name", dest="cluster_name",
                                                                  help="clustername which will be used to control(stop/verify) cluster")
                group.add_option("-s", "--servers", dest="num_servers",
                                                              type="int", help="number of servers. default: 2 if afr or dht and 4 if stripe ")
                group.add_option("-c", "--clients", dest="num_clients",
                                                                 type="int", help="number of clients")
                group.add_option("-p", "--port", dest="port",
                                                                 type="int", help="port number to connect to")
                group.add_option("-v", "--version", dest="version",
                                         default=glusterfs_version, help="version of the glusterfs to be used. ")
                group.add_option("-S","--stop", dest="stop_cluster",
                                                                 help="will stop  the cluster and removes export dirs and mount pts")
		group.add_option("-D","--status",dest="status_cluster",help="display status of a cluster")
		group.add_option("-A","--show",dest="show_cluster",help="display cluster environment")
		group.add_option("-r","--run",dest="run_file",help="will execute the script on cluster's client mount pts")
                

                parser.add_option_group(group)
                (options, args) = parser.parse_args()


                if options.stop_cluster is None:
				if options.run_file is not None:
						self.retval='e'
						self.run_file = options.run_file
						self.cloud_name = options.cluster_name + " " 
						return 
				if options.show_cluster is not None:
						self.retval='d'
						return
				if options.status_cluster is not None:
						self.retval='c'
						#self.cloud_id=options.status_cluster
						self.cloud_name=options.status_cluster + " "
						return
								

				old_std=logging_start()
                                if options.cluster_type is None or options.cluster_name is None:
						logging_stop(old_std)
                                                print "Error: Cluster type is mandatory. Please provide a cluster type (afr|dht|stripe)"
                                                print usage_str
                                #raise ValueError
                                                sys.exit(2)

                                elif str(options.cluster_type) == "afr":
                                                print('You have asked for mirroring cluster')
						logging_stop(old_std)
                                
                                elif str(options.cluster_type) == "stripe":
                                                print('You have asked for a stripe cluster')
						logging_stop(old_std)
                                
                                elif str(options.cluster_type) == "dht":
                                                print('You have asked for a distributed cluster')
                                		logging_stop(old_std)

                                else:
						logging_stop(old_std)
                                                print "Invalid cluster type . Please provide a valid cluster type (afr|dht|stripe)"
                                #raise ValueError
                                                sys.exit(2)
                

                                
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
						if str(options.cluster_type) == "afr":
                                                                #print "Number of servers is kept as default"
                                                                #print options.num_servers
                                                                options.num_servers = total_servers_afr
                                               
						elif str(options.cluster_type) == "stripe":
								options.num_servers=total_servers_stripe

						else:
								options.num_servers=total_servers_dht
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
                                                print " " #Building the storage cluster with glusterfs version", options.version 

                                #print 'The options provided are:\ncluster type:', options.cluster_type, 'Cluster name:', options.cluster_name, 'Number of servers:', options.num_servers, 'Number of clients:', options.num_clients, 'Port Number:', options.port, 'Version:', options.version
				self.retval='a'
                else:
                                
				self.cloud_name=options.stop_cluster + " " 
				self.retval='b'
				return


                self.cloud_type=options.cluster_type
                self.cloud_name=options.cluster_name+" "
                self.num_servers=options.num_servers
                self.num_clients=options.num_clients
                self.port=options.port
                self.glusterfs_version=options.version
		#reset path and start cmd
		self.default_glusterfs_path="/opt/glusterfs/"+self.glusterfs_version
		self.cmd_glfs_start=self.default_glusterfs_path+"/sbin/glusterfsd -f "

		old_std=logging_start()
                print "\n----------------------"
                print "Cloud-type : ",self.cloud_type,"\ncloud-name  : ",self.cloud_name,"\nnum-servers",self.num_servers,"\nnum-clients",self.num_clients
                print "port",self.port,"version:",self.glusterfs_version
		print "path is " ,self.default_glusterfs_path,"cmd",self.cmd_glfs_start
                print '\n----------------------'
		logging_stop(old_std)

	def open_connection(self,path):
		try:
			old_std=logging_start()
			print "open_connection:start"
			self.db=sqlite3.connect(path)
			self.cursor=self.db.cursor()
		except Exception,e:
			print "Failed : Connecting to database",path
			logging_stop(old_std)
			self.db,self.cursor=None,None
			print e.args
		else:
			print "Connected to database successfully:",path
			logging_stop(old_std)
			return self.db,self.cursor


	def initialize_processtables(self):
		try:
			old_std=logging_start()
			print "initialize_processtables:start"

		
			n=self.num_servers
			m=self.num_clients
		
			overflow=False
			#generate cloud id
			print "running query:","select count(*) from cloud_seed where cloud_name=",self.cloud_name
			self.cursor.execute("select count(*) from cloud_seed where cloud_name=?",(self.cloud_name,))
			for row in self.cursor:
				if row[0] == 0:
					print "okay"
				else:
					logging_stop(old_std)
					print self.cloud_name,"already exists - Please select unique cloud name."
					sys.exit(2)

			self.cursor.execute("select max(rowid) from cloud_seed")
			for row in self.cursor:
				print row[0]
			
			if row[0] == None:
				print "it's empty"
				self.cloud_id=1000
				print "cloud-id",self.cloud_id
			else:
				print "it has this value :",row[0]
				self.cloud_id=1000
				print "new self.cloud_id:",self.cloud_id,"+",row[0],"=",self.cloud_id+row[0]
				self.cloud_id=self.cloud_id+row[0]

			#create record in cloud_seed 
			self.cursor.execute(SQL_STMT_INIT_CLOUD,(self.cloud_id,self.cloud_name,"init",self.glusterfs_version,))
				

			s=(n,)
			t=(m,)
			#get total records from server_pool and client_pool
			self.cursor.execute(SQL_STMT_GET_S_MAX)
			
			self.server_pool_max=0
			# get the max. rowid
	                for row in self.cursor:
         			 self.server_pool_max=row[0]
	                print "max records in serverl pool:",self.server_pool_max


			#Fetch records from server_pool  
			if n <= self.server_pool_max :
				self.cursor.execute(SQL_STMT_GET_S_POOL,s)
				# read values
				for row in self.cursor:
					self.server_pool_list.append(row)
			
			else:
				print "overflow set as true"
				overflow=True
				counter=n/self.server_pool_max
				while(counter > 0):
					print counter
					counter=counter - 1

					self.cursor.execute(SQL_STMT_GET_S_POOL,(self.server_pool_max,))
                                	# read values
	                                for row in self.cursor:
	        	                       	self.server_pool_list.append(row)		
				#fetch any remaining records
				self.cursor.execute(SQL_STMT_GET_S_POOL,(n%self.server_pool_max,))
                                # read values
                                for row in self.cursor:
        	                        self.server_pool_list.append(row)	
	
			print self.server_pool_list

			# get the max. rowid
			self.client_pool_max=0
                        self.cursor.execute(SQL_STMT_GET_C_MAX)

                        for row in self.cursor:
                                self.client_pool_max=row[0]

                        print self.client_pool_max

			#Fetch records from client_pool 
                        if m <= self.client_pool_max :
                                self.cursor.execute(SQL_STMT_GET_C_POOL,t)
                                # read values
                                for row in self.cursor:
                                        self.client_pool_list.append(row)

                        else:
                                counter=m/self.client_pool_max
                                while(counter > 0):
                                        print counter
                                        counter=counter - 1

                                        self.cursor.execute(SQL_STMT_GET_C_POOL,(self.client_pool_max,))
                                        # read values
                                        for row in self.cursor:
                                                self.client_pool_list.append(row)
                                #fetch any remaining records
                                self.cursor.execute(SQL_STMT_GET_C_POOL,(m%self.client_pool_max,))
                                # read values
                                for row in self.cursor:
                                        self.client_pool_list.append(row)

			
				if nfs == "on" :
					#make nfsserver as unique
					nfsserver=self.client_pool_list[0]
					nfs_count = self.client_pool_list.count(nfsserver)
					tmp=nfs_count
					while tmp > 0 :
						self.client_pool_list.remove(nfsserver)
						tmp = tmp -1
					#insert to top
					self.client_pool_list.insert(0,nfsserver)
					bkup=self.client_pool_list[1]
					tmp=nfs_count - 1
					while tmp > 0 :
						self.client_pool_list.append(bkup)
						tmp = tmp -1
				
			print   self.client_pool_list

			#insert into server_process
			count=1
			for record in self.server_pool_list:
				self.cursor.execute(SQL_STMT_INSERT_S_PROCESS,(record[0],record[1],self.cloud_id,count,));
				count=count+1
			
			#insert into client_process
			count=1
			for record in self.client_pool_list:
				self.cursor.execute(SQL_STMT_INSERT_C_PROCESS,(record[0],record[1],self.cloud_id,count,));
				count=count+1

		except Exception,e:
			print e.args
			print "** failed**:initialize_processtables:while copying records from  pool table to process table" 
			logging_stop(old_std)
		else:
			print "client/server records retrived from pool and inserted into process table."	
			logging_stop(old_std)
			return overflow


	def commit_changes(self):
		try:
			old_std=logging_start()
			print "commit_changes:start"
			self.db.commit()
		except Exception,e:
			print e.args
			print "commit failed"
			logging_stop(old_std)
		else:
			print "Changes are committed to database"
			logging_stop(old_std)

	def mount_remote_server(self):
		try:
			old_std=logging_start()
			print "mount_remote_server:start"
			# get records from server_process table
			self.cursor.execute(SQL_STMT_S_PROCESS_GETBY_CLOUDID,(self.cloud_id,))
			# read values
			counter=0
			for row in self.cursor:
				self.server_process_list.append(row)


			for record in self.server_process_list:
				print "\nRunning pdsh on server ",record[0]
				print "Creating Export  directories for server",record[0],":",record[5],"with cloud_id",record[1]

				#type case int into string
				str_cloud_id = str(record[1])
				str_snum = str(record[5])
				
				#create export dirs
				export_dir=cloud_export_dir+str_cloud_id + "/export"+str_snum
				cmd=cmd_pdsh + pdsh_user + record[0] +cmd_pdsh2+ cmd_mkdir + export_dir
				print "Running cmd:",cmd
				os.system(cmd)				
				
				#create spec dir for volume files
				cmd=cmd_pdsh + pdsh_user + record[0] +cmd_pdsh2+ cmd_mkdir + cloud_spec_dir + str_cloud_id +"/server"+ str_snum
				print "Running cmd:",cmd
				os.system(cmd)				
				

				
				print "update server_process table"
				self.cursor.execute(SQL_STMT_UPDATE_S_PROCESS,(export_dir,record[1],record[5],record[0],));
				#add it in dictionary key:value == > key=cloud_id+snum , value=server
				self.server_dict[str_cloud_id+"-"+str_snum]=record[0]


				#second dictionary for export dirs
				self.exportdir_dict[str_cloud_id+"-"+str_snum]=export_dir.strip()

				print self.server_dict
				print self.exportdir_dict

				#TODO check free port
				

		except Exception,e:
			print e.args
			print "**FAILED**:mount_remote_server: While creating export dirs with pdsh in remote server ."
			logging_stop(old_std)
		else:
			print "Creating export dirctories  in remote server .done"
			logging_stop(old_std)

	def mount_remote_client(self):
		try:
			old_std=logging_start()
			print "mount_remote_client:start"
			self.cursor.execute(SQL_STMT_C_PROCESS_GETBY_CLOUDID,(self.cloud_id,))
			# read values
			counter=0
			for row in self.cursor:
				self.client_process_list.append(row)


			for record in self.client_process_list:
				print "\nRunning pdsh on client",record[0]
				print "Creating mount points for client:",record[0],":",record[5],"with cloud_id",record[1]

				#type case int into string
				str_cloud_id = str(record[1])
				str_cnum=str(record[5])

				mnt_pt=cloud_dir +str_cloud_id + "/"+str_cnum
				cmd=cmd_pdsh + pdsh_user + record[0] +cmd_pdsh2+ cmd_mkdir + mnt_pt
				print "Running cmd:",cmd
				os.system(cmd)				
				

				print "Running mkdir cmd:",cmd
				self.cursor.execute(SQL_STMT_UPDATE_C_PROCESS,(mnt_pt,record[1],record[5],record[0],));
				os.system(cmd)				

				#create spec dir for volume files
				cmd=cmd_pdsh + pdsh_user + record[0] +cmd_pdsh2+ cmd_mkdir + cloud_spec_dir+ str_cloud_id +"/client"+ str_cnum
				print "Running cmd:",cmd
				os.system(cmd)				

				#add it in dictionary key:value == > key=cloud_id+cnum , value=client
				self.client_dict[str_cloud_id+"-"+str_cnum]=record[0]
				#second dictionary for mnt_pts
				self.mntpt_dict[str_cloud_id+"-"+str_cnum]=mnt_pt.strip()

				print self.client_dict
				print self.mntpt_dict


		except Exception,e:
			print e.args
			print "**FAILED**:mount_remote_client: While creating mount points with pdsh in remote client ."
			logging_stop(old_std)
		else:
			print "Creating mount points with pdsh in remote client .done"
			logging_stop(old_std)


	def create_config_files(self,overflow):
		try:
				old_std=logging_start()
				print "create_config_files:start"
				
				#create local temp vol file dir.
				cmd= cmd_mkdir + "/tmp/" + str(self.cloud_id)
				print "Running cmd:",cmd
				os.system(cmd)				


				#things todo incase of num_server > server_pool_max : START
				
				if overflow==True:
					print "True"
                                        server_export=""
					dummy="_dummy_"
                                        for snum in range(1,self.num_servers+1):
                                                print snum
                                                key=str(self.cloud_id)+"-"+str(snum)
                                                print self.server_dict[key]+":"+self.exportdir_dict[key]

						if snum <= self.server_pool_max:
							server_export += self.server_dict[key]+":"+self.exportdir_dict[key]+" "
						else:
							print "It's greater now"
							server_export += self.server_dict[key]+dummy+str(snum)+":"+self.exportdir_dict[key]+" "
							self.dummy_server_files.append(self.server_dict[key]+dummy+str(snum))
							
						
					print server_export
				else:
					print "false" 


					#END:things todo incase of num_server > server_pool_max 

	                                print "Going to creat config file with " ,self.num_servers ," servers" ,self.num_clients,"clients"
        	                        print "Fetch self.server_dict and export_dict"


                	                server_export=""
                        	        for snum in range(1,self.num_servers+1):
                                	        print snum
                                        	key=str(self.cloud_id)+"-"+str(snum)
	                                        print self.server_dict[key]+":"+self.exportdir_dict[key]

        	                                server_export += self.server_dict[key]+":"+self.exportdir_dict[key]+" "



				#Run volgen

				if self.cloud_type == "afr":
					type="-r 1"  
				elif self.cloud_type == "stripe":
					type="-r 0"
				else:
					type=" "

								
				cmd_volgen=self.default_glusterfs_path + "/bin/glusterfs-volgen -n " +self.cloud_name
				cmd=cmd_volgen +type+" -p "+str(self.port)+" "+server_export +" -c " +"/tmp/"+ str(self.cloud_id)

				print cmd
				os.system(cmd)

				#: change port in serv files & port+hostname in client file
				text="transport.socket.listen-port "
				search =text + str(self.port)
				newport=self.port
				#first set default port value and overwrite it below if needed.
				self.cursor.execute(SQL_STMT_UPDATE_DEFPORT_S_PROCESS,(newport,self.cloud_id,));
				if overflow == True:
					print "Changing server port in :"
					for f in self.dummy_server_files:
						fn="/tmp/"+str(self.cloud_id)+"/"+f+"-"+self.cloud_name.strip()+"-export.vol"
						print fn
					 	#Change port number	
						newport = newport + 1
						replace=text + str(newport)+" "
						#replace 
						for line in fileinput.FileInput(fn,inplace=1):
					        	line = line.replace(search,replace)
							print line
						print "update port for ",self.cloud_id,f ,"as :",newport
						s_port=f.split("_dummy_")
						print "for server :",s_port[0],"snum is",s_port[1]

	                                        #update port in table
        	                                print "updating table:"
                	                        self.cursor.execute(SQL_STMT_UPDATEPORT_S_PROCESS,(newport,self.cloud_id,s_port[1],s_port[0],));



					print "change remote-hostname in client vol files"
					newport=self.port
					text="remote-host "
					for serv in self.dummy_server_files:
						cflag=0
						s1=str(serv)
						end=s1.index("_")
							
						search=text + s1
		                                replace=text + s1[0:end]

						print "search string is " ,search ,"and replace is ",replace

					        client_f="/tmp/"+str(self.cloud_id)+"/"+self.cloud_name.strip()+"-tcp.vol"
						print "client file : ",client_f
						for line in fileinput.FileInput(client_f,inplace=1):
							if "option remote-host" in line and s1 in line:
        	        	                              line = line.replace(search,replace)
							      cflag=1
							#Now change the port number
							if cflag and "transport.remote-port" in line:
							       a=line.rstrip().split(" ")
							       newport = newport + 1
							       #a[-1]=str(int(a[-1])+1)
							       a[-1]=str(newport)
							       line=' '.join(a)
							       cflag=0
							print line
						fileinput.close()
						#format client file=>remove blank lines
						for lines in fileinput.FileInput(client_f, inplace=1): 	
					 		lines = lines.strip()
						 	if lines == '': continue
							print lines
						fileinput.close()

						#
						for lines in fileinput.FileInput(client_f, inplace=1): 	
							lines=lines.strip()
						 	ret = lines.find("end-volume")
						 	if ret == -1:
								print lines
							else:
								print lines
								print "\n"
						fileinput.close()

				time.sleep(5)	

				#Now vol files are available under /tmp/self.cloud_id move it to respective server and client machines.
				#T0D0 -- if nfs is set, add acl to server and append nfs-xlator to client 
				if nfs == "on":
					root="/tmp/"
					#edit client files
					path=os.path.join(root,str(self.cloud_id))
					alines=["\nvolume nfs\n"," type nfs/server\n"," option rpc-auth.addr.allow *\n"," subvolumes statprefetch\n","end-volume\n"]
					os.chdir(path)
					for clientfile in glob.glob("*-tcp.vol"):
						    data=open(clientfile).readlines()
						    data+=alines
						    open("temp","w").write(''.join(data))
						    os.rename("temp",clientfile)
					#edit server files
		
					for svrfile in glob.glob("*-export.vol"):
						for line in fileinput.FileInput(svrfile,inplace=1):
							line = line.replace("subvolumes posix1","subvolumes posix-ac")
							print line
					#add ac 
					alines2=["\nvolume posix-ac\n"," type features/access-control\n"," subvolumes posix1 \n","end-volume\n"]
					for svrfile in glob.glob("*-export.vol"):
						f=0
						for line in fileinput.FileInput(svrfile,inplace=1):
							ind=line.find("end-volume")
							if ind!=-1 and not f:
								line=line[:ind+10] + ''.join(alines2) + line[ind+10:]
								f=1
							print line
					
				if overflow == False:
					for snum in range(1,self.num_servers+1):
						print snum
						key=str(self.cloud_id)+"-"+str(snum)
						print self.server_dict[key]
						#move volfiles
						src= "/tmp/"+str(self.cloud_id)+"/"+	self.server_dict[key]+"-"+self.cloud_name.strip()+"-export.vol"
						dest=cloud_spec_dir + str(self.cloud_id) +"/server"+ str(snum)
						cmd=cmd_kaput +  self.server_dict[key] +" "+src+" " + dest
						print "\nMoving server vol.files.Running cmd:",cmd
						os.system(cmd)				
						#TODO:Move mount.sh - automount /opt- and run it using pdsh
						cmd=cmd_kaput +  self.server_dict[key] +" "+opt_mount_path+" /tmp"
						os.system(cmd)

						cmd=cmd_pdsh + pdsh_user + self.server_dict[key]  +cmd_pdsh2+ "/tmp/mount_opt.sh"
                                                print "Running cmd:",cmd
                                                os.system(cmd)


				else:
					dummy="_dummy_"
                                        for snum in range(1,self.num_servers+1):
                                                print snum
                                                key=str(self.cloud_id)+"-"+str(snum)
                                                print self.server_dict[key]
                                                #move volfiles
						
                                                if snum <= self.server_pool_max:
	                                                src= "/tmp/"+str(self.cloud_id)+"/"+self.server_dict[key]+"-"+self.cloud_name.strip()+"-export.vol"
						else:
			                           src= "/tmp/"+str(self.cloud_id)+"/"+self.server_dict[key]+dummy+str(snum)+"-"+self.cloud_name.strip()+"-export.vol"
                                                dest=cloud_spec_dir + str(self.cloud_id) +"/server"+ str(snum)
                                                cmd=cmd_kaput +  self.server_dict[key] +" "+src+" " + dest
                                                print "\nMoving server vol.files.Running cmd:",cmd
                                                os.system(cmd)
						#TODO: move mount.sh to /tmp - automount /opt if not exits and run it using pdsh
						cmd=cmd_kaput +  self.server_dict[key] +" "+opt_mount_path+" /tmp"
						os.system(cmd)
					
	                                        cmd=cmd_pdsh + pdsh_user + self.server_dict[key]  +cmd_pdsh2+ "/tmp/mount_opt.sh"
                                                print "Running cmd:",cmd
                                                os.system(cmd)


				for cnum in range(1,self.num_clients+1) :
	 				print cnum
					key=str(self.cloud_id)+"-"+str(cnum)
					print self.client_dict[key]

					print "Moving client vol.files."
					src="/tmp/"+str(self.cloud_id)+"/"+self.cloud_name.strip()+"-tcp.vol"
					dest=cloud_spec_dir+str(self.cloud_id)+"/client"+str(cnum)
					cmd=cmd_kaput +self.client_dict[key]+" "+src+" "+dest
					print "Running cmd:",cmd
					os.system(cmd)
					#TODO:move mount.sh to clients /tmp and run it using pdsh	
					cmd=cmd_kaput +  self.client_dict[key] +" "+opt_mount_path+" /tmp"
					os.system(cmd)
                                        cmd=cmd_pdsh + pdsh_user + self.client_dict[key]  +cmd_pdsh2+ "/tmp/mount_opt.sh"
                                        print "Running cmd:",cmd
                                        os.system(cmd)
                                        if nfs=="on":
                                                        cmd1=" /etc/init.d/rpcbind start"
							cmd=cmd_pdsh + pdsh_user + self.client_dict[key]  +cmd_pdsh2+ cmd1
                                                        os.system(cmd)
							cmd1=" /etc/init.d/portmap start"
							cmd=cmd_pdsh + pdsh_user + self.client_dict[key]  +cmd_pdsh2+ cmd1
                                                        os.system(cmd)
							cmd1=" /etc/init.d/nfslock start"
							cmd=cmd_pdsh + pdsh_user + self.client_dict[key]  +cmd_pdsh2+ cmd1
							os.system(cmd)



		
		except Exception,e:
				print e.args
				print "**ERROR**:create_config_files: while moving vol files"
				logging_stop(old_std)
		else:
				print "vol. files are moved to appropriate server/client machines"			
				logging_stop(old_std)

				return 


	def start_server(self):
		try:
				old_std=logging_start()
				print "start_server:start"
				print self.server_dict
				dummy="_dummy_"
				#Now vol files are available servers.So start it
                                for snum in range(1,self.num_servers+1):
                                        print snum
                                        key=str(self.cloud_id)+"-"+str(snum)
                                        print self.server_dict[key]
                                        #start servers
					logfile=cloud_spec_dir+ str(self.cloud_id) +"/server"+ str(snum)+"/"+"gs.log"

                                        if snum <= self.server_pool_max:
						servfile= str(self.cloud_id) +"/server"+ str(snum)+"/"+ self.server_dict[key]+"-"+self.cloud_name.strip()+"-export.vol"
					else:

						servfile1= str(self.cloud_id) +"/server"+ str(snum)+"/"+ self.server_dict[key]+dummy+str(snum)+"-"
						servfile=servfile1+self.cloud_name.strip()+"-export.vol"
					pidfile= "  -L NONE --pid-file=/tmp/server.pid"

					cmd=cmd_pdsh + pdsh_user + self.server_dict[key] +cmd_pdsh2+self.cmd_glfs_start+ cloud_spec_dir+servfile+" -l "+logfile+pidfile
                                        print "\nStarting server.Running cmd:",cmd
                                        os.system(cmd)

					#pid and log file in server_process table
					cmd=cmd_pdsh + pdsh_user + self.server_dict[key] + cmd_pdsh2 + cmd_cat + "/tmp/server.pid > /tmp/gs.pid"
					print "Recording pid",cmd
					os.system(cmd)
					cmd=cmd_cat + "/tmp/gs.pid"
					print "server pid is :"	
					os.system(cmd)
					f = open("/tmp/gs.pid", "r")
                                        for line in f:
                                       	           pid  = line.strip().split()[1].lower()
                                                   print " -->", pid
                                        f.close()
					#update pid in table 
					print "updating table:"
					self.cursor.execute(SQL_STMT_UPDATEPID_S_PROCESS,(pid,logfile,self.cloud_id,snum,self.server_dict[key],));

		except Exception,e:
					print e.args
					print " **ERROR**start_server: Starting servers and updating pid in server_process  table"			
					logging_stop(old_std)
		else:
					print "Done.Servers are started and pids recorded"				
					logging_stop(old_std)

	def start_client(self):

		try:
				old_std=logging_start()
				print "start_client:start"
				print self.client_dict 
				#if nfs == "on":
					#cmd="/bin/echo '128' > /proc/sys/sunrpc/tcp_slot_table_entries"
					#print cmd
					#os.system("echo '128' > /proc/sys/sunrpc/tcp_slot_table_entries")
					#Now vol files are available client.So start it
					#If nfs is set  - for the first client - start it as nfs/server and for other mount it.
				run = 1
				skip = 0
				nfsserver=" "
                                for cnum in range(1,self.num_clients+1):
                                        print cnum
                                        key=str(self.cloud_id)+"-"+str(cnum)
                                        print "client is ==>",self.client_dict[key]
			                #start client
					#logfile=cloud_spec_dir+ str(self.cloud_id) +"/client"+ str(cnum)+"/"+"gc.log"
					logfile="/mnt/gc.log"

					if nfs == "on" and run == 1:
						print "nfs=on run=1 skip=0",self.client_dict[key]
                                                clientfile=str(self.cloud_id)+"/client"+str(cnum)+"/"+self.cloud_name.strip()+"-tcp.vol "
						#reset run --if needed
						if cnum == self.num_servers:
							run = 0
						skip = 0
						nfsserver = self.client_dict[key]
						#make sure rpcbin/portmap started before nfs server
						cmd1=" /etc/init.d/rpcbind start"
                                                cmd=cmd_pdsh + pdsh_user + self.client_dict[key]  +cmd_pdsh2+ cmd1
                                                os.system(cmd)
                                                cmd1=" /etc/init.d/portmap start"
                                                cmd=cmd_pdsh + pdsh_user + self.client_dict[key]  +cmd_pdsh2+ cmd1
                                                os.system(cmd)

						
					elif nfs == "on" and run == 0:
						print "nfs=on run=0 skip=1",self.client_dict[key]
						#mount these here itself and skip the 'other mount' below
						#nfsserver_set will tell - how many nfs servers are there.
						nfsserver_set=(self.num_clients - self.num_servers) / self.num_servers
				
						pos = cnum % self.num_servers
						if pos==0:
							pos=self.num_servers

						#if nfsserver_set > 1:	
						#	if cnum == 1:
						#		key_dummy=str(self.cloud_id)+"-"+str(pos)
						#		nfsserver=self.client_dict[key_dummy]
						#	elif cnum % nfsserver_set != 0:
						#		key_dummy=str(self.cloud_id)+"-"+str(pos)
						#		nfsserver=self.client_dict[key_dummy]
						#else:
						key_dummy=str(self.cloud_id)+"-"+str(pos)
                                                nfsserver=self.client_dict[key_dummy]


						print "client_dict=",self.client_dict
						print "nfsserver=",nfsserver,"++",cnum,"++",self.cloud_id
						cmd1=cmd_mount+" "+nfsserver+":/statprefetch " +self.mntpt_dict[key]
						cmd=cmd_pdsh + pdsh_user + self.client_dict[key]  +cmd_pdsh2+ cmd1
					  	print "running nfs mount:",cmd
					 	os.system(cmd)
						skip = 1						
					else:
						clientfile=str(self.cloud_id)+"/client"+str(cnum)+"/"+self.cloud_name.strip()+"-tcp.vol "+self.mntpt_dict[key]
					
					if skip != 1:
						pidfile= "  -L NONE --pid-file=/tmp/client.pid"
						cmd1=cmd_pdsh + pdsh_user + self.client_dict[key] +cmd_pdsh2+self.cmd_glfs_start+cloud_spec_dir+clientfile+" -l "
					 	#cmd1=cmd_pdsh + pdsh_user + self.client_dict[key] +cmd_pdsh2+" /opt/glusterfs/3.0.4avail3_32bit/sbin/glusterfsd -f "+cloud_spec_dir+clientfile+" -l "
						cmd=cmd1+logfile+pidfile
						print "\nStarting client.Running cmd:",cmd
                       	        	        os.system(cmd)
		
						#record client-pid and log file in client table.
                	                        cmd=cmd_pdsh + pdsh_user + self.client_dict[key] + cmd_pdsh2 + cmd_cat + "/tmp/client.pid > /tmp/gc.pid"
                        	                print "Recording pid",cmd
                                	        os.system(cmd)
                                        	cmd=cmd_cat + "/tmp/gc.pid"
	                                        print "client pid is :"
        	                                os.system(cmd)
						f = open("/tmp/gc.pid", "r")
                        	                for line in f:
                                	                   pid  = line.strip().split()[1].lower()
                                        	           print " -->", pid
	                                        f.close()
			                        #update pid in table
                	                        self.cursor.execute(SQL_STMT_UPDATEPID_C_PROCESS,(pid,logfile,self.cloud_id,cnum,self.client_dict[key],));
	
						#sleep for 5 seconds 
						time.sleep(5)
						os.system("/bin/sync")
						
		except Exception,e:
					print e.args
					print " **ERROR**:start_client: Starting client and updating pid in client_process  table" 


					logging_stop(old_std)
		else:
					print "Clients started and pid recorded"
					logging_stop(old_std)
	
	def active_cloud(self):

		try:
					old_std=logging_start()
					print "active_cloud:start"
					#update cloud_id as active
					self.cursor.execute(SQL_STMT_ACTIVATE_CLOUD,(self.cloud_type,self.cloud_id,));
		except Exception,e:
					print e.args
					print "**ERROR** :active_cloud: while trying to change cloud status from init to active"
					logging_stop(old_std)
		else:
				logging_stop(old_std)
				print "-----------------------------------------------------------------------------------------------------------------------"
				print self.cloud_type," cloud",self.cloud_name,"with",self.num_servers,"server(s) and",self.num_clients,"client(s) is active now."
				print "------------------------------------------------------------------------------------------------------------------------"
		
					

	#Cloud stop functions
	def check_valid(self):
		try:
					#self.cloud_id=raw_input("Cloud id ?")
					self.cursor.execute(SQL_STMT_CHECK_CLOUD,(self.cloud_name,));
					for row in self.cursor:
						state=str(row[0])
						type=str(row[1])
						self.cloud_id=row[2]
						self.glusterfs_version=row[3]
					if state=="active":
						print "----------------------------------------------"
						print "The",type," cloud ",self.cloud_name," is active and running glusterfs-",self.glusterfs_version
						return True
					else:
						if state=="init":
							print "Cloud is in init state"
						else:
							print "Cloud not found.Call 911."
							return False
		
		except Exception,e:
					old_std=logging_start()
					print ' ' #e.args
					print "**ERROR** :check_valid: while retriving cloud id",SQL_STMT_CHECK_CLOUD,self.cloud_name
					logging_stop(old_std)
		else:
					print " "

	def stop_client(self):
		try:
					old_std=logging_start()
					print "stop_client:start"
					nfs_run=1
					self.cursor.execute(SQL_STMT_C_PROCESS_GETBY_CLOUDID,(self.cloud_id,));
					for row in self.cursor:
                                 	        print "name:",row[0],"cloudid:",row[1],"pid:",row[2]
						print "mntpt:",row[3],"prt",row[4]
						print "cnum:",row[5],"state:",row[6],"log:",row[7]

						if str(row[6]) == "running" or nfs == "on":
							#if nfs=="on" and nfs_run == 1:
							#		#kill this pid
							#		nfs_run=0
							#		cmd=cmd_pdsh + pdsh_user + str(row[0]) +cmd_pdsh2+ cmd_kill + str(row[2])
        		                                #               print "Running cmd:",cmd
                        		                #               os.system(cmd)

							#else:
								cmd=cmd_pdsh + pdsh_user + str(row[0]) +cmd_pdsh2+ cmd_umount + str(row[3])
		        	                        	print "Running cmd:",cmd
			                	                os.system(cmd)
						nfs_run = 0
						print " Removing spec files "
						cmd=cmd_pdsh + pdsh_user + str(row[0]) + cmd_pdsh2+ cmd_mv + cloud_spec_dir+str(self.cloud_id) + cloud_seed_trash
						print cmd
						os.system(cmd)
						#empty cloud_seed trash
                                                cmd=cmd_pdsh + pdsh_user + str(row[0]) + cmd_pdsh2+ cmd_rm + cloud_seed_trash +"/"+ str(self.cloud_id)
                                                print "removing spec from trash ",cmd
                                                os.system(cmd)

							
						print " Removing mnt dirs "
                                                cmd=cmd_pdsh + pdsh_user + str(row[0]) + cmd_pdsh2+ cmd_mv + cloud_dir+str(self.cloud_id) + cloud_seed_trash
                                                print cmd
                                                os.system(cmd)
						
						#empty tmp dir
                                                cmd=cmd_pdsh + pdsh_user + str(row[0]) + cmd_pdsh2+ cmd_rm + " /tmp/" + str(self.cloud_id)
                                                os.system(cmd)
						#empty cloud_seed trash -again
                                                cmd=cmd_pdsh + pdsh_user + str(row[0]) + cmd_pdsh2+ cmd_rm + cloud_seed_trash +"/" + str(self.cloud_id)
                                                print "removing mnt from trash",cmd
                                                os.system(cmd)
	        	                        #update in table
					print SQL_STMT_UPDATESTATUS_C_PROCESS,self.cloud_id
        	        	        self.cursor.execute(SQL_STMT_UPDATESTATUS_C_PROCESS,(self.cloud_id,));

	

                except Exception,e:
                                        print e.args
                                        print "**ERROR** :stop_client: while retriving cloud id from client process"
					logging_stop(old_std)
                else:
                                        print "done."
					logging_stop(old_std)

        def stop_server(self):
                try:
					old_std=logging_start()
					print "stop_server:start"
                                        self.cursor.execute(SQL_STMT_S_PROCESS_GETBY_CLOUDID,(self.cloud_id,));
			
					s_list=[]
                                        for row in self.cursor:
                                                print "name:",row[0],"cloudid:",row[1],"pid:",row[2]
                                                print "export:",row[3],"prt",row[4]
                                                print "snum:",row[5],"state:",row[6],"log:",row[7]
						#s_list.append(row[0])
						if str(row[6]) == "running":
	                                                cmd=cmd_pdsh + pdsh_user + str(row[0]) +cmd_pdsh2+ cmd_kill + str(row[2])
        	                                        print "Running cmd:",cmd
                	                                os.system(cmd)
						#add servers to list and rm/mv directories -iff it not already done.
						if s_list.count(row[0]) == 0:
						 s_list.append(row[0])						
	                                         cmd=cmd_pdsh + pdsh_user + str(row[0]) + cmd_pdsh2+ cmd_mv + cloud_spec_dir+str(self.cloud_id) + cloud_seed_trash
		                                 print " Removing spec files and export pts,Cmd:",cmd
        		                         os.system(cmd)
                        	                 cmd=cmd_pdsh + pdsh_user + str(row[0]) + cmd_pdsh2+ cmd_rm + cloud_seed_trash +"/"+ str(self.cloud_id)
						 print "run1:",cmd
                                	         os.system(cmd)
                                        	 cmd=cmd_pdsh + pdsh_user + str(row[0]) + cmd_pdsh2+ cmd_mv + cloud_export_dir+str(self.cloud_id) + cloud_seed_trash
						 print "run2",cmd
						 os.system(cmd)
	                                         cmd=cmd_pdsh + pdsh_user + str(row[0]) + cmd_pdsh2+ cmd_rm + cloud_seed_trash +"/"+ str(self.cloud_id)
						 print "run3",cmd
        	                                 os.system(cmd)

					#update table
					self.cursor.execute(SQL_STMT_UPDATESTATUS_S_PROCESS,(self.cloud_id,));


		except Exception,e:
                                        print e.args
                                        print "**ERROR** :stop_server: while retriving cloud id"
					logging_stop(old_std)
                else:
                                        print "done."
					logging_stop(old_std)


	def deactivate_cloud(self):
		try:
					old_std=logging_start()
					print "deactivate_cloud"
					#update cloud_id as free
                                        self.cursor.execute(SQL_STMT_DEACTIVATE_CLOUD,(self.cloud_id,));

                except Exception,e:
                                        print e.args
                                        print "**ERROR** :deactivate_cloud: while retriving cloud id"
					logging_stop(old_std)
                else:
                                        print "done."
					logging_stop(old_std)
	
	def client_status(self):
                try:
					old_std=logging_start()
					print "client_status:start"
					print SQL_STMT_C_PROCESS_GETBY_CLOUDID,self.cloud_id
					logging_stop(old_std)
                                        self.cursor.execute(SQL_STMT_C_PROCESS_GETBY_CLOUDID,(self.cloud_id,));
					print "---------------------------------------------------------------"
					print "client:\tmount-point:\tlogfile:\tstatus:\tpid"
					print "---------------------------------------------------------------"
					nfs_check="yes"
					update_clients=[]
					update_clients_dict={}
                                        for row in self.cursor:
					       if nfs_check == "yes":
					  	     #check status of pid in remote
	                                               cmd=cmd_pdsh + pdsh_user + str(row[0]) +cmd_pdsh2+cmd_pid1+str(row[2])+cmd_pid2 +" > /tmp/pname2"
        	                                       #print "checking pid status :",cmd
                	                               os.system(cmd)
                        	                       time.sleep(2)

                                               #
                                               if os.stat("/tmp/pname2")[6] == 0:
                                                        pname = -1
                                               else:
                                                       f = open("/tmp/pname2", "r")
                                                       for line in f:
                                                                pname  = line.find("glusterfs")
                                                       f.close()

					       #turn off status check for nfs-clients -- since mount has no pid
					       if nfs == "on":
							nfs_check="no" #don't check for mounts 
							pname = 1
                                               if pname == -1:
                                                        #print "glusterfs not running"

							val=row[5]
                                                        update_clients.append(val)
                                                        str_cloudid=str(self.cloud_id)
                                                        str_cnum=str(row[5])
                                                        update_clients_dict[str_cloudid+"-"+str_cnum]=str(row[0])

                                                        print row[0],": ---- :",row[7],": not-running : --"
                                               else:

                                               		print row[0],":",row[3],":",row[7],":",row[6],":",row[2]



					#fetch cnum from list and client name from dict
					old_std=logging_start()
                                        for record in update_clients:
                                                        name= update_clients_dict[str_cloudid+"-"+str(record)]
                                                        self.cursor.execute(SQL_STMT_CSTATUS_CHECK_UPDATE,(self.cloud_id,record,name,))
							print SQL_STMT_CSTATUS_CHECK_UPDATE,self.cloud_id,name,record

		except Exception,e:
                                        print e.args
                                        print "**ERROR** :client_status: while retriving cloud id"
					logging_stop(old_std)
                else:
					logging_stop(old_std)
					return None

	def server_status(self):
		try:
					old_std=logging_start()
					print "server_status:start"
					print "running query:",SQL_STMT_S_PROCESS_GETBY_CLOUDID,self.cloud_id
					logging_stop(old_std)
                                        self.cursor.execute(SQL_STMT_S_PROCESS_GETBY_CLOUDID,(self.cloud_id,));
					print "----------------------------------------"
					print "server:directory:port:logfile:status:pid"
					print "----------------------------------------"

					update_servers=[]
					update_servers_dict={}

                                        for row in self.cursor:
					       old_std=logging_start()
					       print "check status of pid in remote ",row[0],"==>",row[5]
					       cmd=cmd_pdsh + pdsh_user + str(row[0]) +cmd_pdsh2+cmd_pid1+str(row[2])+cmd_pid2 +" > /tmp/pname"
					       print "checking pid status :",cmd
					       os.system(cmd)
					       logging_stop(old_std)
					       time.sleep(2)
			
					       #
					       if os.stat("/tmp/pname")[6] == 0:
							pname = -1
					       else:
						       f = open("/tmp/pname", "r")
						       for line in f:
						       		pname  = line.find("glusterfs")
						       f.close()

					       if pname == -1:
						 	#print "glusterfs not running"
							#update db status
							#self.cursor.execute(SQL_STMT_SSTATUS_CHECK_UPDATE,(self.cloud_id,row[5],row[0],));
							val=row[5]
							update_servers.append(val)
							str_cloudid=str(self.cloud_id)
							str_snum=str(row[5])
							update_servers_dict[str_cloudid+"-"+str_snum]=str(row[0])
							
							print row[0],":",row[3],":",row[4],":",row[7],": not-running : --"
					       else:
	                                               print row[0],":",row[3],":",row[4],":",row[7],":",row[6],":",row[2]
					#fetch snum from list and server name from dict
					
					old_std=logging_start()
					for record in update_servers:
							print update_servers_dict[str_cloudid+"-"+str(record)]
							name= update_servers_dict[str_cloudid+"-"+str(record)]
							self.cursor.execute(SQL_STMT_SSTATUS_CHECK_UPDATE,(self.cloud_id,record,name,))
					
							print SQL_STMT_SSTATUS_CHECK_UPDATE,self.cloud_id,record,name
					logging_stop(old_std)
		except Exception,e:
					old_std=logging_start()
                                        print e.args
                                        print "**ERROR** :server_status: while retriving cloud id"
					logging_stop(old_std)
                else:
					return None

	def checkall_valid(self):
                try:
					old_std=logging_start()
					print "checkall_valid:start"
					logging_stop(old_std)
					cloud_ids=[]
					cloud_ids_type={}
					cloud_ids_name={}
					cloud_ids_version={}
                                        self.cursor.execute(SQL_STMT_CHECKALL_CLOUD);
                                        for row in self.cursor:
						cid=str(row[0])
                                                cloud_ids.append(cid)
						cloud_ids_type[str(cid)]=str(row[1])
						cloud_ids_name[str(cid)]=str(row[2])
						cloud_ids_version[str(cid)]=str(row[3])

					for  id in cloud_ids:
						print "\t\t~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
						print "\t\t\tcloud :",cloud_ids_name[id]," :type:",cloud_ids_type[id],": glusterfs:",cloud_ids_version[id]
						print "\t\t~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
						self.cloud_id=int(id)
						self.server_status()
						self.client_status()

                except Exception,e:
					old_std=logging_start()
                                        print e.args
                                        print "**ERROR** :checkall_valid: while retriving cloud id"
					logging_stop(old_std)
                else:
                                        print " "

		#get client records

	def  get_client_info(self):
		try:
					old_std=logging_start()
                                        print "get_client_info:start"
                                        logging_stop(old_std)
					self.cursor.execute(SQL_STMT_CHECK_CLOUD,(self.cloud_name,));
                                        for row in self.cursor:
                                                state=str(row[0])
                                                type=str(row[1])
                                                self.cloud_id=row[2]


					self.cursor.execute(SQL_STMT_C_PROCESS_GETBY_CLOUDID,(self.cloud_id,))
        		                # read values
                        		counter=0
		                        for row in self.cursor:
                		                self.client_process_list.append(row)

					if nfs == "on":
						#remove nfs-server
						self.client_process_list.pop(0)

		                        for record in self.client_process_list:
                                		print " mount points for client:",record[0],":",record[3],"with cloud_id",record[1]
					

		except Exception,e:
					old_std=logging_start()
                                        print e.args
                                        print "**ERROR** : get_client_info:while retriving cloud id"
                                        logging_stop(old_std)


		else:
					print " "
				

	def run_on_mount_pt(self):
		try:
					old_std=logging_start()
                                        print "run_on_mount_ptstart"
					print "clients are : ",self.client_process_list

			
					#before moving the script edit it - added mntpt to run_file and 
					#move the file to remote clients and execute the script at mount pt
					cmd = cmd_cp+self.run_file+" /tmp"
					os.system(cmd)
					for record in self.client_process_list:
						#Edit the file
						for line in fileinput.FileInput(self.run_file,inplace=1):
                                                        line = line.replace("CLOUD_MNT_PT",str(record[3]))
                                                        print line
				
					
						cmd=cmd_kaput + str(record[0])+" "+self.run_file+" " +str(record[3])
						print "running:",cmd
						os.system(cmd)

						#copy the original file from tmp
						cmd= cmd_mv + self.run_file +" " +cloud_seed_trash
					 	os.system(cmd)
					
						cmd= cmd_cp +"/tmp/"+self.run_file+" ."
						os.system(cmd)

						#now files are move to remove client mnt pt - now execute the script
						#for record in self.client_process_list: - execute the file before someone modifies it :) 
					        cmd=cmd_pdsh + pdsh_user + str(record[0]) +cmd_pdsh2+ str(record[3])+"/"+ self.run_file +" &"
						#cmd=cmd_pdsh + pdsh_user + str(record[0]) +cmd_pdsh2+ "/tmp/"+ self.run_file 
		                                print "Running script:",cmd,"on client",str(record[0])
        		                        os.system(cmd)
					logging_stop(old_std)


                except Exception,e:
                                        old_std=logging_start()
                                        print e.args
                                        print "**ERROR** : run_on_mount_pt:while processing run file"
                                        logging_stop(old_std)


                else:
                                        print " "

###############MAIN PART#############


obj1=Cloud_db()
CONN,CURSOR=obj1.open_connection(dbpath)
ans=obj1.retval
if ans == 'a':
	overflow=obj1.initialize_processtables()
	obj1.mount_remote_server()
	obj1.mount_remote_client()
	obj1.commit_changes()
	obj1.create_config_files(overflow)
	obj1.start_server()
	obj1.start_client()
	obj1.active_cloud()
	obj1.commit_changes()
	#TODO : create save points are appropriate places and then commit.
elif ans == 'b':
 	if obj1.check_valid():
		print "stopping client(s)."
		obj1.stop_client()
		print "stoppping server(s)."
		obj1.stop_server()
		obj1.deactivate_cloud()
		obj1.commit_changes()
		print "cloud stopped."
	
	else:
		print "nothing to kill"	
	
elif ans == 'c':
	if obj1.check_valid():
		obj1.server_status()
		obj1.client_status()
		obj1.commit_changes()
	else:
		print "Cloud not found.Blown away?"
elif ans == 'd':
	obj1.checkall_valid()
	obj1.commit_changes()

elif ans == 'e':
		obj1.get_client_info()
		obj1.run_on_mount_pt()

else:
		print "Invalid input ?"


