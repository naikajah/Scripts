#!/bin/sh
echo "vm post provisioning test result:"$'\n' > vm_check_op.txt

##Checking if hostname and IP present in /etci/hosts file.
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
                echo "hostname or IP address not present in hosts file" >> vm_check_op.txt

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

##checking Telnet
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

##checking open ports
echo "Below ports are open:" >> vm_check_op.txt
rpm -qa | grep nmap
if [[ $? -eq 0 ]]
then
        nmap -sS -O 127.0.0.1 | egrep -w -R 'open' >> vm_check_op.txt
else
        yum -y install nmap
        nmap -sS -O 127.0.0.1 | egrep -w -R 'open' >> vm_check_op.txt
fi

##Checking rsyslog status
sudo service rsyslog status >> vm_check_op.txt

##Checkin softwares
#com1="sshpass -p $1 ssh -o StrictHostKeyChecking=no root@$2 $3"
mysql -V
sw_check=$?
if [[ "$sw_check" -eq 0 ]];
then
	echo "Mysql is installed and running" >> vm_check_op.txt
else
	echo "Mysql is corrupt or not installed" >> vm_check_op.txt
fi

##Checking multipath status
multipath -v
if [[ $? -eq 0 ]]
then
	echo "Multipath is running" >> vm_check_op.txt
else
	echo "Multipath is not installed or not running" >> vm_check_op.txt
fi

##List Device drivers installed.
drivers=( $(lsmod | awk '{ print $1}') )
echo "Following Device Drivers are installed:" >> vm_check_op.txt
for driver in "${drivers[@]}"
do	
	echo $driver >> vm_check_op.txt
done

ps2pdf
if [[ $? -ne 1 ]]
then
        yum -y install ghostscript
fi

rpm -qa | grep enscript
if [[ $? -eq 0 ]]
then
        enscript vm_check_op.txt -o - | ps2pdf - vm_check_op.pdf
else
        yum -y install enscript
        enscript vm_check_op.txt -o - | ps2pdf - vm_check_op.pdf
fi
