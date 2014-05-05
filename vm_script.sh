#!/bin/sh
#!/usr/bin/expect -f

##Checking if hostname and IP present in /etc/hosts file.
h_name=$(hostname)

echo "vm post provisioning test result:"$'\n' > $h_name'.log'
echo "Hosts File : ">> $h_name'.log'

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
                echo "hostname '$h_name' and IP address '$pr_ip' present in hosts file" >> $h_name'.log'
        else
                echo "hostname '$h_name' or IP address '$pr_ip' not present in hosts file" >> $h_name'.log'

        fi
	
	#sed -e 's/[\t ]//g;/^$/d' /etc/hosts > /tmp/tempfile.txt
	if sed -e 's/[\t ]//g;/^$/d' /etc/hosts | grep -q '127.0.0.1localhost.localdomainlocalhost'
	then
		echo "hosts file format is correct" >> $h_name'.log'
	else
		echo "hosts file format is incorrect" >> $h_name'.log'
	fi
else
        echo "hosts file does not exist" >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##checking Telnet
echo "Telnet : ">> $h_name'.log'
if [ -f /etc/xinetd.d/telnet ];
then
#	sed -e 's/[\t ]//g;/^$/d' /etc/xinetd.d/telnet > /tmp/tempfile.txt
	if sed -e 's/[\t ]//g;/^$/d' /etc/xinetd.d/telnet | grep -q 'disable=yes'
	then
		echo "telnet is Disabled" >> $h_name'.log'
	else
		echo "telnet is Enabled" >> $h_name'.log'
	fi
else
	echo "telnet is Disabled" >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##checking open ports
echo "Open Ports : ">> $h_name'.log'
rpm -qa | grep nmap
if [[ $? -eq 0 ]]
then
        nmap -sS -O 127.0.0.1 | egrep -w -R 'open' >> $h_name'.log'
else
        yum -y install nmap
        nmap -sS -O 127.0.0.1 | egrep -w -R 'open' >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##Checking rsyslogd status
echo "Rsyslogd : ">> $h_name'.log'
sudo service rsyslog status >> $h_name'.log'

echo $'\n' >> $h_name'.log'
##Checkin softwares
echo "Applications : ">> $h_name'.log'
#com1="sshpass -p $1 ssh -o StrictHostKeyChecking=no root@$2 $3"
mysql -V
sw_check=$?
if [[ "$sw_check" -eq 0 ]];
then
	echo "Mysql is installed and running" >> $h_name'.log'
else
	echo "Mysql is corrupt or not installed" >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##Checking multipath status
echo "Multipath : ">> $h_name'.log'
multipath -v
if [[ $? -eq 0 ]]
then
	echo "Multipath is running" >> $h_name'.log'
else
	echo "Multipath is not installed or not running" >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##List Device drivers installed.
echo "Device Drivers : ">> $h_name'.log'
drivers=( $(lsmod | awk '{ print $1}') )
for driver in "${drivers[@]}"
do	
	echo $driver >> $h_name'.log'
done

echo $'\n' >> $h_name'.log'
##Image Deployment error test
echo "Image Deployment errors: ">> $h_name'.log'

##Find Errors in File /var/log/anaconda.log
while read line;
do
        op=$(echo -e "$line\n" | awk '{print $2}')
        if [[ $op == "ERROR" ]];
        then
                echo -e "$line\n" >> $h_name'.log'
        fi
done < /var/log/anaconda.log

##Find Errors in File /var/log/dmesg
while read line;
do
        op=$(echo -e "$line\n" | awk '{print $2}')
        if [[ $op == "ERROR" ]];
        then
                echo -e "$line\n" >> $h_name'.log'
        fi
done < /var/log/dmesg

##Find Errors in File /var/log/boot.log
while read line;
do
        op=$(echo -e "$line\n" | awk '{print $2}')
        if [[ $op == "ERROR" ]];
        then
                echo -e "$line\n" >> $h_name'.log'
        fi
done < /var/log/boot.log


echo $'\n' >> $h_name'.log'
##Remote root telnet test
echo "Remote root telnet test : ">> $h_name'.log'
r_login=$(grep -c 'PermitRootLogin no' /etc/ssh/sshd_config)
if [[ $r_login -eq 1 ]]
then
	echo "PermitRootLogin : No" >> $h_name'.log'
else
	echo "PermitRootLogin : Yes" >> $h_name'.log'
fi

grep tty /etc/securetty
if [[ $? -eq 0 ]]
then
	echo "tty : Fail" >> $h_name'.log'
else
	echo "tty : Pass" >> $h_name'.log'
fi

grep pts /etc/securetty
if [[ $? -eq 0 ]]
then
	echo "pts : Fail" >> $h_name'.log'
else
	echo "pts : Pass" >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##Services status test
echo "Services status test : ">> $h_name'.log'
finger
if [[ $? -eq 0 ]]
then
	echo "Finger : Running" >> $h_name'.log'
else
	echo "Finger : Not Running" >> $h_name'.log'
fi

anonFTP
if [[ $? -eq 0 ]]
then
	echo "anonFTP : Running" >> $h_name'.log'
else
	echo "anonFTP : Not Running" >> $h_name'.log'
fi

tftp -V
if [[ $? -eq 0 ]]
then
	echo "tftp : Running" >> $h_name'.log'
else
	echo "tftp : Not Running" >> $h_name'.log'
fi

ps aux | grep sendmail
if [[ $? -eq 0 ]]
then
	echo "sendmail : Running" >> $h_name'.log'
else
	echo "sendmail : Not Running" >> $h_name'.log'
fi

rwho
if [[ $? -eq 0 ]]
then
	echo "rwho : Running" >> $h_name'.log'
else
	echo "r who: Not Running" >> $h_name'.log'
fi

netstat
if [[ $? -eq 0 ]]
then
	echo "netstat : Running" >> $h_name'.log'
else
	echo "netstat : Not Running" >> $h_name'.log'
fi

yppasswd
if [[ $? -eq 0 ]]
then
	echo "yppasswd : Running" >> $h_name'.log'
else
	echo "yppasswd : Not Running" >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##iptable test:
rpm -qa | grep iptables
if [[ $? -eq 0 ]]
then
	rpm -e iptables-*
	echo "iptables : iptables uninstalled/disabled" >> $h_name'.log'
else
	echo "iptables : iptables disabled" >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##Compare Swap size to be double of RAM size.
mem=$(free | awk 'FNR == 2 {print $2}')
swap=$(cat /proc/swaps | awk 'FNR == 2 {print $3}')
mem=$((mem+mem))
if [[ $mem == $swap ]];
then
	echo "SWAP Test : Pass" >> $h_name'.log'
	echo "SWAP size : "$swap >> $h_name'.log'
else
	echo "SWAP Test : Fail" >> $h_name'.log'
	echo "SWAP size : "$swap >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##Checking BMC status -- LIN-IQ-18
echo "BMC agent : " >> $h_name'.log'
ps -ef | grep PatrolAgents
result=$?

if [[ "${result}" -eq 0 ]];
then
	echo "BMC agent is installed and running" >> $h_name'.log'
else
	echo "BMC agent is corrupt or not installed" >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##Checking TSM status -- LIN-IQ-19
echo "TSM agent : " >> $h_name'.log'
ps -ef | grep tsm
result=$?

if [[ "${result}" -eq 0 ]];
then
	echo "tsm agent is installed and running" >> $h_name'.log'
else
	echo "tsm agent is corrupt or not installed" >> $h_name'.log'
fi

echo $'\n' >> $h_name'.log'
##Checking TSCM status -- LIN-IQ-20
echo "TSCM agent : " >> $h_name'.log'
/opt/monitor/tivoli/client/jacclient status
result=$?

if [[ "${result}" -eq 0 ]];
then
	echo "TSCM agent is installed and running" >> $h_name'.log'
else
	echo "TSCM agent is corrupt or not installed" >> $h_name'.log'
fi


##Copy output file $h_name'.log' to Dev server
expect -v
if [[ $? -eq 0 ]]
then
	expect -c "
	set timeout -1
	spawn scp -r -o StrictHostKeyChecking=no $h_name.log root@50.97.254.178:/opt/SimpleSoftlayer/vmcheck_op
	match_max 100000
	expect -exact 'admin@50.97.254.178's password: '
	send -- \"root123\r\"
	expect eof"


else
	yum -y install expect
	expect -c "
	set timeout -1
	spawn scp -r -o StrictHostKeyChecking=no $h_name.log root@50.97.254.178:/opt/SimpleSoftlayer/vmcheck_op
	match_max 100000
	expect -exact 'admin@50.97.254.178's password: '
	send -- \"root123\r\"
	expect eof"
fi

