#!/bin/sh
##Checking if hostname and IP present in /etci/hosts file.
echo "Hosts File : ">> $(hostname).txt
h_name=$(hostname)

ips=( $(ifconfig | grep 'inet addr' | cut -d ':' -f 2 | awk '{ print $1 }') )

if [ -f /etc/hosts ];
then
        $(grep -q $h_name /etc/hosts)
        h_op=$?
        ip_op=1
        pr_ip=""
        for ip in "${ips[@]}"
        do

                if [[ "$ip" != "127.0.0.1" ]];
                then
                        $(grep -q $ip /etc/hosts)
			ip_op=$?
			if [[ "$ip_op" -eq 0 ]];
        		then
                        	pr_ip=$ip
                        	break;
			fi

                fi
        done

	if [[ "$h_op" -eq 0 && "$ip_op" -eq 0 ]];
        then
                echo "hostname '$h_name' and IP address '$pr_ip' present in hosts file" >> $(hostname).txt
        else
                echo "hostname '$h_name' or IP address '$pr_ip' not present in hosts file" >> $(hostname).txt

        fi
	
	#sed -e 's/[\t ]//g;/^$/d' /etc/hosts > /tmp/tempfile.txt
	if sed -e 's/[\t ]//g;/^$/d' /etc/hosts | grep -q '127.0.0.1localhost.localdomainlocalhost'
	then
		echo "hosts file format is correct" >> $(hostname).txt
	else
		echo "hosts file format is incorrect" >> $(hostname).txt
	fi
else
        echo "hosts file does not exist" >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##checking Telnet
echo "Telnet : ">> $(hostname).txt
if [ -f /etc/xinetd.d/telnet ];
then
#	sed -e 's/[\t ]//g;/^$/d' /etc/xinetd.d/telnet > /tmp/tempfile.txt
	if sed -e 's/[\t ]//g;/^$/d' /etc/xinetd.d/telnet | grep -q 'disable=yes'
	then
		echo "telnet is Disabled" >> $(hostname).txt
	else
		echo "telnet is Enabled" >> $(hostname).txt
	fi
else
	echo "telnet is Disabled" >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##checking open ports
echo "Open Ports : ">> $(hostname).txt
rpm -qa | grep nmap
if [[ $? -eq 0 ]]
then
        nmap -sS -O 127.0.0.1 | egrep -w -R 'open' >> $(hostname).txt
else
        yum -y install nmap
        nmap -sS -O 127.0.0.1 | egrep -w -R 'open' >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##Checking rsyslogd status
echo "Rsyslogd : ">> $(hostname).txt
sudo service rsyslog status >> $(hostname).txt

echo $'\n' >> $(hostname).txt
##Checkin softwares
echo "Applications : ">> $(hostname).txt
#com1="sshpass -p $1 ssh -o StrictHostKeyChecking=no root@$2 $3"
mysql -V
sw_check=$?
if [[ "$sw_check" -eq 0 ]];
then
	echo "Mysql is installed and running" >> $(hostname).txt
else
	echo "Mysql is corrupt or not installed" >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##Checking multipath status
echo "Multipath : ">> $(hostname).txt
multipath -v
if [[ $? -eq 0 ]]
then
	echo "Multipath is running" >> $(hostname).txt
else
	echo "Multipath is not installed or not running" >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##List Device drivers installed.
echo "Device Drivers : ">> $(hostname).txt
drivers=( $(lsmod | awk '{ print $1}') )
for driver in "${drivers[@]}"
do	
	echo $driver >> $(hostname).txt
done

echo $'\n' >> $(hostname).txt
##Image Deployment error test
echo "Image Deployment error: ">> $(hostname).txt
dmesg=$(grep -i error  /var/log/dmesg)
op1=$?
btlg=$(grep -i error  /var/log/boot.log)
op2=$?
ana=$(grep -i error  /var/log/anaconda.log)
op3=$?
if [[ $op1 -ne 0 && $op2 -ne 0 && $op3 -ne 0 ]]
then
	echo "No Errors" >> $(hostname).txt
else
	echo $dmesg $'\n' $btlg $'\n' $ana>> $(hostname).txt
fi


echo $'\n' >> $(hostname).txt
## system configuration Check.
echo "System Configuration : ">> $(hostname).txt
os=$(lsb_release -a | grep 'Description' | cut -d ':' -f2)
echo "Operating System :"$os >> $(hostname).txt
proc=$(grep -c processor /proc/cpuinfo)
echo "Processor(s) : "$proc >> $(hostname).txt
cat /proc/cpuinfo | grep "^cpu cores" | uniq >> $(hostname).txt
cat /var/log/dmesg | grep Memory >> $(hostname).txt

echo $'\n' >> $(hostname).txt
##Remote root telnet test
echo "Remote root telnet test : ">> $(hostname).txt
r_login=$(grep -c 'PermitRootLogin no' /etc/ssh/sshd_config)
if [[ $r_login -eq 1 ]]
then
	echo "PermitRootLogin : No" >> $(hostname).txt
else
	echo "PermitRootLogin : Yes" >> $(hostname).txt
fi

grep tty /etc/securetty
if [[ $? -eq 0 ]]
then
	echo "tty : Fail" >> $(hostname).txt
else
	echo "tty : Pass" >> $(hostname).txt
fi

grep pts /etc/securetty
if [[ $? -eq 0 ]]
then
	echo "pts : Fail" >> $(hostname).txt
else
	echo "pts : Pass" >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##Services status test
echo "Services status test : ">> $(hostname).txt
finger
if [[ $? -eq 0 ]]
then
	echo "Finger : Running" >> $(hostname).txt
else
	echo "Finger : Not Running" >> $(hostname).txt
fi

anonFTP
if [[ $? -eq 0 ]]
then
	echo "anonFTP : Running" >> $(hostname).txt
else
	echo "anonFTP : Not Running" >> $(hostname).txt
fi

tftp -V
if [[ $? -eq 0 ]]
then
	echo "tftp : Running" >> $(hostname).txt
else
	echo "tftp : Not Running" >> $(hostname).txt
fi

ps aux | grep sendmail
if [[ $? -eq 0 ]]
then
	echo "sendmail : Running" >> $(hostname).txt
else
	echo "sendmail : Not Running" >> $(hostname).txt
fi

rwho
if [[ $? -eq 0 ]]
then
	echo "rwho : Running" >> $(hostname).txt
else
	echo "r who: Not Running" >> $(hostname).txt
fi

netstat
if [[ $? -eq 0 ]]
then
	echo "netstat : Running" >> $(hostname).txt
else
	echo "netstat : Not Running" >> $(hostname).txt
fi

yppasswd
if [[ $? -eq 0 ]]
then
	echo "yppasswd : Running" >> $(hostname).txt
else
	echo "yppasswd : Not Running" >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##iptable test:
rpm -qa | grep iptables
if [[ $? -eq 0 ]]
then
	rpm -e iptables-*
	echo "iptables : iptables uninstalled/disabled" >> $(hostname).txt
else
	echo "iptables : iptables disabled" >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##Compare Swap size to be double of RAM size.
mem=$(free | awk 'FNR == 2 {print $2}')
swap=$(cat /proc/swaps | awk 'FNR == 2 {print $3}')
mem=$((mem+mem))
if [[ $mem == $swap ]];
then
	echo "SWAP Test : Pass" >> $(hostname).txt
	echo "SWAP size : "$swap >> $(hostname).txt
else
	echo "SWAP Test : Fail" >> $(hostname).txt
	echo "SWAP size : "$swap >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##Checking BMC status -- LIN-IQ-18
echo "BMC agent : " >> $(hostname).txt
ps -ef | grep -v grep | grep PatrolAgents
result=$?

if [[ "${result}" -eq 0 ]];
then
	echo "BMC agent is installed and running" >> $(hostname).txt
else
	echo "BMC agent is corrupt or not installed" >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##Checking TSM status -- LIN-IQ-19
echo "TSM agent : " >> $(hostname).txt
ps -ef | grep -v grep | grep tsm
result=$?

if [[ "${result}" -eq 0 ]];
then
	echo "tsm agent is installed and running" >> $(hostname).txt
else
	echo "tsm agent is corrupt or not installed" >> $(hostname).txt
fi

echo $'\n' >> $(hostname).txt
##Checking TSCM status -- LIN-IQ-20
echo "TSCM agent : " >> $(hostname).txt
/opt/monitor/tivoli/client/jacclient status
result=$?

if [[ "${result}" -eq 0 ]];
then
	echo "TSCM agent is installed and running" >> $(hostname).txt
else
	echo "TSCM agent is corrupt or not installed" >> $(hostname).txt
fi


##Copy output file $(hostname).txt to Dev server
sshpass
if [[ $? -eq 0 ]]
then
	sshpass -p Passw0rd scp -r -o StrictHostKeyChecking=no $(hostname).txt admin@50.97.195.66:/home/admin/vmcheck_op_dir
else
	os_ver=$(uname -m)
	if [[ "$os_ver" == "x86_64" ]]; 
	then
		wget http://pkgs.repoforge.org/sshpass/sshpass-1.05-1.el3.rf.x86_64.rpm
		rpm -Uvh sshpass-1.05-1.el3.rf.x86_64.rpm
		sshpass -p Passw0rd scp -r -o StrictHostKeyChecking=no $(hostname).txt admin@50.97.195.66:/home/admin/vmcheck_op_dir
		rm -rf sshpass-1.05-1.el3.rf.x86_64.rpm
	else
		wget http://pkgs.repoforge.org/sshpass/sshpass-1.05-1.el6.rf.i686.rpm
		rpm -Uvh sshpass-1.05-1.el6.rf.i686.rpm
		sshpass -p Passw0rd scp -r -o StrictHostKeyChecking=no $(hostname).txt admin@50.97.195.66:/home/admin/vmcheck_op_dir
		rm -rf sshpass-1.05-1.el6.rf.i686.rpm
	fi
fi
