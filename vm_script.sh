#!/bin/sh
echo "vm post provisioning test result:"$'\n' > vm_check_op.txt

##Checking if hostname and IP present in /etci/hosts file.
echo "Hosts File : ">> vm_check_op.txt
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
                echo "hostname '$h_name' and IP address '$pr_ip' present in hosts file" >> vm_check_op.txt
        else
                echo "hostname '$h_name' or IP address '$pr_ip' not present in hosts file" >> vm_check_op.txt

        fi
	
	#sed -e 's/[\t ]//g;/^$/d' /etc/hosts > /tmp/tempfile.txt
	if sed -e 's/[\t ]//g;/^$/d' /etc/hosts | grep -q '127.0.0.1localhost.localdomainlocalhost'
	then
		echo "hosts file format is correct" >> vm_check_op.txt
	else
		echo "hosts file format is incorrect" >> vm_check_op.txt
	fi
else
        echo "hosts file does not exist" >> vm_check_op.txt
fi

echo $'\n' >> vm_check_op.txt
##checking Telnet
echo "Telnet : ">> vm_check_op.txt
if [ -f /etc/xinetd.d/telnet ];
then
#	sed -e 's/[\t ]//g;/^$/d' /etc/xinetd.d/telnet > /tmp/tempfile.txt
	if sed -e 's/[\t ]//g;/^$/d' /etc/xinetd.d/telnet | grep -q 'disable=yes'
	then
		echo "telnet is Disabled" >> vm_check_op.txt
	else
		echo "telnet is Enabled" >> vm_check_op.txt
	fi
else
	echo "telnet is Disabled" >> vm_check_op.txt
fi

echo $'\n' >> vm_check_op.txt
##checking open ports
echo "Open Ports : ">> vm_check_op.txt
rpm -qa | grep nmap
if [[ $? -eq 0 ]]
then
        nmap -sS -O 127.0.0.1 | egrep -w -R 'open' >> vm_check_op.txt
else
        yum -y install nmap
        nmap -sS -O 127.0.0.1 | egrep -w -R 'open' >> vm_check_op.txt
fi

echo $'\n' >> vm_check_op.txt
##Checking rsyslogd status
echo "Rsyslogd : ">> vm_check_op.txt
sudo service rsyslog status >> vm_check_op.txt

echo $'\n' >> vm_check_op.txt
##Checkin softwares
echo "Applications : ">> vm_check_op.txt
#com1="sshpass -p $1 ssh -o StrictHostKeyChecking=no root@$2 $3"
mysql -V
sw_check=$?
if [[ "$sw_check" -eq 0 ]];
then
	echo "Mysql is installed and running" >> vm_check_op.txt
else
	echo "Mysql is corrupt or not installed" >> vm_check_op.txt
fi

echo $'\n' >> vm_check_op.txt
##Checking multipath status
echo "Multipath : ">> vm_check_op.txt
multipath -v
if [[ $? -eq 0 ]]
then
	echo "Multipath is running" >> vm_check_op.txt
else
	echo "Multipath is not installed or not running" >> vm_check_op.txt
fi

echo $'\n' >> vm_check_op.txt
##List Device drivers installed.
echo "Device Drivers : ">> vm_check_op.txt
drivers=( $(lsmod | awk '{ print $1}') )
for driver in "${drivers[@]}"
do	
	echo $driver >> vm_check_op.txt
done

##Copy output file vm_check_op.txt to Dev server
os_ver=$(uname -m)
if [[ "$os_ver" == "x86_64" ]]; 
then
	wget http://pkgs.repoforge.org/sshpass/sshpass-1.05-1.el3.rf.x86_64.rpm
	rpm -Uvh sshpass-1.05-1.el3.rf.x86_64.rpm
	sshpass -p Passw0rd scp -r -o StrictHostKeyChecking=no vm_check_op.txt admin@50.97.195.66:/home/admin/vmcheck_op_dir
	rm -rf sshpass-1.05-1.el3.rf.x86_64.rpm
else
	wget http://pkgs.repoforge.org/sshpass/sshpass-1.05-1.el6.rf.i686.rpm
	rpm -Uvh sshpass-1.05-1.el6.rf.i686.rpm
	sshpass -p Passw0rd scp -r -o StrictHostKeyChecking=no vm_check_op.txt admin@50.97.195.66:/home/admin/vmcheck_op_dir
	rm -rf sshpass-1.05-1.el6.rf.i686.rpm
fi
