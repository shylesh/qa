create table cloud_seed(
	cloud_id int unique,
	cloud_name varchar(50),
	status varchar(10),
	type varchar(15),
	version  varchar(10)
);

create table server_process(
	server varchar(50),
	cloud_id int,
	server_pid int,
	export_dir varchar(100),
	port int,
	snum int,
	status varchar(15),
	logfile varchar(50)
);

create table client_process(
	client varchar(50) ,
	cloud_id int,
	client_pid int,
	mount_pt varchar(100),
	port int,
	cnum int,
	status varchar(15),
	logfile varchar(50)
);

create table server_pool(
	servername varchar(50) ,
	status varchar(10),
	ipaddress varchar(15) 
);

create table client_pool(
	clientname varchar(50) ,
	status varchar(10),
	ipaddress varchar(15) 
);

insert into server_pool (servername,status,ipaddress) values 
	 ("ec2-67-202-6-25.compute-1.amazonaws.com","free","10.212.187.79");
insert into server_pool (servername,status,ipaddress) values
	 ("ec2-174-129-181-3.compute-1.amazonaws.com","free","10.244.145.156");
insert into server_pool (servername,status,ipaddress) values 
	 ("ec2-75-101-171-113.compute-1.amazonaws.com","free","10.244.43.207");
insert into server_pool (servername,status,ipaddress) values 
	 ("ec2-67-202-34-30.compute-1.amazonaws.com","free","10.244.163.32");


insert into client_pool (clientname,status,ipaddress) values 
	("ec2-72-44-36-203.compute-1.amazonaws.com","free","10.245.222.227");
