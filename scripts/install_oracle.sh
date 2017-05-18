#!/bin/bash
#Oralce 11g R2 for linux
#Creat Date 2016-06-07

#Prepare 

SYS_MEM=`grep MemTotal /proc/meminfo |awk -F " " '{print $2}'`
SYSCTL=/etc/sysctl.conf
LIMITS=/etc/security/limits.conf
PAM=/etc/pam.d/login
PROFILE=/etc/profile
BASH_PROFILE=/home/oracle/.bash_profile
ORACLE_PACKAGE1=`find /u01 -name "linux.x64_11gR2_database_1of2.zip"`
ORACLE_PACKAGE2=`find /u01 -name "linux.x64_11gR2_database_2of2.zip"`
PACKAGE_SRC=`find /u01 -name "runInstaller"`

#Check Mem
function check_mem(){
if [ $SYS_MEM -lt 4194304 ];then
	echo -e "\n\e[1;31m Memoary is less then 4G \e[0m"
        exit 2
else
	echo -e "\n\e[1;33m Memoary is  $SYS_MEM kb \e[0m"
fi
}

#Check User
function check_root() {
if [ $USER != "root" ];then
	echo -e "\n\e[1;31m you user is $USER,please ues root. \e[0m"
	exit 2
else
	echo -e "\e[1;36m check root ...Done! \e[0m"
fi
}

function check_oracle(){
if [ ! -z `cat /etc/passwd |grep oracle`  ] ;then
	/usr/sbin/userdel -r oracle
        echo -e "\e[1;33m delete user oracle\e[0m"
fi
if [ -z `cat /etc/group |grep oinstall`  ] ;then
	/usr/sbin/groupadd oinstall
else
        echo -e "\e[1;33m group oinstall already exist \e[0m"
fi
if [ -z `cat /etc/group |grep dba`  ] ;then
	/usr/sbin/groupadd dba
else
        echo -e "\e[1;33m group dba already exist \e[0m"
fi
/usr/sbin/useradd oracle -g oinstall -G dba && echo "oracle" |passwd oracle --stdin
}

#Check Package
function check_package() {
if [ -z $PACKAGE_SRC  ] ;then
	if [  -z $ORACLE_PACKAGE1  ] ;then
        	echo -e "\e[1;31m can not find $ORACLE_PACKAGE1 \e[0m"
		exit 2
	fi
	if [  -z $ORACLE_PACKAGE2  ] ;then
        	echo -e "\e[1;31m can not find $ORACLE_PACKAGE2 \e[0m"
        	exit 2
	fi
	echo $PACKAGE_SRC
	echo -e "\e[1;36m Unzip $ORACLE_PACKAGE1 \e[0m"	
	unzip -o -q $ORACLE_PACKAGE1
	echo -e "\e[1;36m Unzip $ORACLE_PACKAGE1 ...Done!\e[0m" 
	echo -e "\e[1;36m Unzip $ORACLE_PACKAGE2 \e[0m"	
	unzip -o -q $ORACLE_PACKAGE2
	echo -e "\e[1;36m Unzip $ORACLE_PACKAGE2 ...Done!\e[0m" 
	mv ./database /u01/
fi 

yum install -y binutils-2.* compat-libstdc++-33* elfutils-libelf-0.* elfutils-libelf-devel-* gcc-4.* gcc-c++-4.* glibc-2.* glibc-common-2.* glibc-devel-2.* glibc-headers-2.* ksh-2* libaio-0.* libaio-devel-0.* libgcc-4.* libstdc++-4.* libstdc++-devel-4.* make-3.* sysstat-7.* unixODBC-2.* unixODBC-devel-2.* pdksh*
}

#Check Directories
function check_directories() {
if [ ! -d /oracle_data ];then
	mkdir -p /oracle_data/oradata
	chown -R oracle:oinstall /oracle_data
        chmod -R 775 /oracle_data
	echo  -e "\n\e[1;36m Create /oracle_data ... Done! \e[0m"
else
	chown -R oracle:oinstall /oracle_data
        chmod -R 775 /oracle_data
	echo -e "\n\e[1;33m /oracle_data already exist \e[0m"
fi
if [ ! -d /u01 ];then
	mkdir -p /u01/app
	chown -R oracle:oinstall /u01
	chmod -R 775 /u01
	echo  -e "\n\e[1;36m Create /u01 ... Done! \e[0m"
else
	chown -R oracle:oinstall /u01
        chmod -R 775 /u01
	echo -e "\n\e[1;33m /u01 already exist \e[0m"
fi
}

#Update system config
function update_sysctl() {
if [ ! -z "`cat $SYSCTL |grep fs.aio-max-nr`" ];then
	cat $SYSCTL |grep "fs.aio-max-nr"
else
	echo "fs.aio-max-nr = 1048576" >> $SYSCTL
fi
if [ ! -z "`cat $SYSCTL |grep fs.file-max`" ];then
        cat $SYSCTL |grep "fs.file-max"
else
        echo "fs.file-max = 6815744" >> $SYSCTL
fi
if [ ! -z "`cat $SYSCTL |grep kernel.shmmni`" ];then
        cat $SYSCTL |grep "kernel.shmmni"
else
        echo "kernel.shmmni = 4096" >> $SYSCTL
fi
if [ ! -z "`cat $SYSCTL |grep kernel.sem`" ];then
        cat $SYSCTL |grep "kernel.sem"
else
        echo "kernel.sem = 250 32000 100 128" >> $SYSCTL
fi
if [ ! -z "`cat $SYSCTL |grep net.ipv4.ip_local_port_range`" ];then
        cat $SYSCTL |grep "net.ipv4.ip_local_port_range"
else
        echo "net.ipv4.ip_local_port_range = 9000 65500" >> $SYSCTL
fi
if [ ! -z "`cat $SYSCTL |grep net.core.rmem_default`" ];then
        cat $SYSCTL |grep "net.core.rmem_default"
else
        echo "net.core.rmem_default = 262144" >> $SYSCTL
fi
if [ ! -z "`cat $SYSCTL |grep net.core.rmem_max`" ];then
        cat $SYSCTL |grep "net.core.rmem_max = 4194304"
else
        echo "net.core.rmem_max = 4194304" >> $SYSCTL
fi
if [ ! -z "`cat $SYSCTL |grep net.core.wmem_default`" ];then
        cat $SYSCTL |grep "net.core.wmem_default"
else
        echo "net.core.wmem_default = 262144" >> $SYSCTL
fi
if [ ! -z "`cat $SYSCTL |grep net.core.wmem_max`" ];then
        cat $SYSCTL |grep "net.core.wmem_max"
else
        echo "net.core.wmem_max = 1048586" >> $SYSCTL
fi
/sbin/sysctl -p
}

function update_limits() {
if [ ! -z "`cat $LIMITS |grep "oracle soft nproc"`" ];then
        cat $LIMITS |grep "oracle soft nproc"
else
        echo "oracle soft nproc 2047" >> $LIMITS
fi
if [ ! -z "`cat $LIMITS |grep "oracle hard nproc"`" ];then
        cat $LIMITS |grep "oracle hard nproc"
else
        echo "oracle hard nproc 16384" >> $LIMITS
fi
if [ ! -z "`cat $LIMITS |grep "oracle soft nofile"`" ];then
        cat $LIMITS |grep "oracle soft nofile"
else
        echo "oracle soft nofile 1024" >> $LIMITS
fi
if [ ! -z "`cat $LIMITS |grep "oracle hard nofile"`" ];then
        cat $LIMITS |grep "oracle hard nofile"
else
        echo "oracle hard nofile 65536" >> $LIMITS
fi
if [ ! -z "`cat $LIMITS |grep "oracle soft stack"`" ];then
        cat $LIMITS |grep "oracle soft stack"
else
        echo "oracle soft stack 10240" >> $LIMITS
fi
if [ ! -z "`cat $LIMITS |grep "oracle hard stack"`" ];then
        cat $LIMITS |grep "oracle hard stack"
else
        echo "oracle hard stack 32768" >> $LIMITS
fi
}

function update_profile() {
if [ -z "`cat $BASH_PROFILE |grep "ORACLE_BASE"`" ];then
TMP=/tmp
ORACLE_BASE=/u01/app/oracle
ORACLE_SID=orcl
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1;export ORACLE_HOME
	cat  >> $BASH_PROFILE << EOF
TMP=/tmp;export TMP
TMPDIR=$TMP;export TMPDIR
ORACLE_BASE=/u01/app/oracle;export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1;export ORACLE_HOME
ORACLE_SID=orcl;export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH
export PATH
CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib:$ORACLE_HOME/network/jlib;export CLASSPATH
EOF
	source $BASH_PROFILE
	cat $BASH_PROFILE
else
	source $BASH_PROFILE
	cat $BASH_PROFILE
fi
export LANG=en_US
export DISPLAY=:1.0
xhost +
/etc/init.d/iptables stop
chkconfig iptables off
}



#######################################################################
#check_mem
#check_root
#check_oracle
#check_directories
check_package
#update_sysctl
#update_limits
#update_profile
