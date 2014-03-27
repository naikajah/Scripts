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
		echo "telnet is Enabled" >> $(hostname)p.txt
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

##Copy output file vm_check_op.txt to Dev server
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
