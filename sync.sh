#!/bin/bash
# synchronizing between two remote idm host every minute

log="/opt/openidm/logs/checksum.log"
idm1="192.168.200.165"
idm2="192.168.200.150"

# Generating md5 checksum of the Master:
function create_m_md5(){
	if [ true ]; then
		echo $(date) " --- Starting check! ---" >> $log
		echo $(date) "Master (IDM1) md5 checksum creation started!"  >> $log
		find /opt/openidm/conf -type f -exec md5sum {} + > /opt/openidm/checksum_m.txt
		echo $(date) "Master (IDM1) md5 checksum creation succeeded." >> $log
		sleep 1
	else
		echo $(date) "-- ERROR -- something went wrong with md5 checksum creation on a master (IDM1) idm host." >> $log
	fi
}

# Generating md5 checksum of the Slave:
function create_s_md5(){
	if [ true ]; then
		echo $(date) "Slave (IDM2) md5 checksum creation started!" >> $log
		ssh -p 23 root@$idm2 'find /opt/openidm/conf -type f -exec md5sum {} +' > /opt/openidm/checksum_s.txt  
		echo $(date) "Slave (IDM2) md5 checksum creation succeeded." >> $log
		sleep 1
	else
		echo $(date) "-- ERROR -- something went wrong with md5 checksum creation on a slave (IDM2) idm host." >> $log
	fi 
}

function diff(){
	#chmod 0777 -R /opt/openidm/checksum_m.txt /opt/openidm/checksum_s.txt
	
	sort /opt/openidm/checksum_m.txt -o /opt/openidm/checksum_m.txt 
	sort /opt/openidm/checksum_s.txt -o /opt/openidm/checksum_s.txt 
	sleep 1
	#master=$(/opt/openidm/checksum_m.txt)
	#slave=$(/opt/openidm/checksum_s.txt)
	
	cmp -s /opt/openidm/checksum_m.txt /opt/openidm/checksum_s.txt > /dev/null
	
	if [ $? -eq 0  ]; then
		echo $(date) "The two checksum is equal --> nothing to do!" >> $log
	else
		if [ $? -eq 1  ]; then
			echo $(date) "The master (IDM1) host is newer version then the slave (IDM2) host becouse the md5 parameter is different!" >> $log
			echo $(date) "Copy is required!" >> $log
			ssh -p 23 root@$idm2 'rm -f /opt/openidm/conf/*.json | rm -f /opt/openidm/conf/*.xml | rm -f /opt/openidm/conf/*.properties'
			scp -P 23 /opt/openidm/conf/* root@$idm2:/opt/openidm/conf 
			echo $(date) "The copy of the conf directory from master (IDM1) to slave (IDM2) is done!" >> $log 
	else
			echo $(date) "Something went wrong with the copy of the conf directory!" >> $log	
		fi
	fi
}

function helper_for_log(){
	echo $(date) "--- Finishing process! ---" >> $log
	echo " " >> $log
}

while true
do
	create_m_md5
	create_s_md5
	diff
	helper_for_log
	sleep 5
done

