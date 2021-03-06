#!/bin/bash

sudo useradd dbadmin
sudo echo -e "dbadmin ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
sleep 5

##Install needed Packages
sudo yum -y install dialog
#yum -y install pstack
sudo yum -y install mcelog
sudo yum -y install sysstat

##Create Data and Catalog Directories
sudo mkdir /data

##Get Vertica RPM
sudo wget https://s3.amazonaws.com/verticatestdrive/vertica-8.0.0-3.x86_64.RHEL6.rpm

sudo mv vertica-8.0.0-3.x86_64.RHEL6.rpm /root/vertica-8.0.0-3.x86_64.RHEL6.rpm

##Install Vertica RPM
sudo rpm -Uvh /root/vertica-8.0.0-3.x86_64.RHEL6.rpm

##Determine disks
sudo raid="/dev/sdb"

##Format Disk
sudo mkfs -t ext4 -F $raid

##Add UUID of data disk to FSTAB
sudo DevCon=`blkid /dev/sdb|sed 's_/dev/sdb: UUID="__' | sed 's_" TYPE="ext4"__'` 

sudo echo "UUID=${DevCon} /data ext4 defaults,nofail,nobarrier 0 2" >> /etc/fstab

sudo mount -all

sudo sleep 5

##Create Swapfile
sudo install -o root -g root -m 0600 /dev/null /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1k count=2048k
sudo mkswap /swapfile
sudo swapon /swapfile
sudo echo "/swapfile       swap    swap    auto      0       0" >> /etc/fstab

##Set Vertica Requirements
sudo echo '/sbin/blockdev --setra 2048 /dev/sda' >> /etc/rc.local
sudo echo '/sbin/blockdev --setra 2048 /dev/sdc' >> /etc/rc.local

sudo /sbin/blockdev --setra 2048 /dev/sda
sudo /sbin/blockdev --setra 2048 /dev/sdc

sudo echo 'if test -f /sys/kernel/mm/transparent_hugepage/enabled; then' >> /etc/rc.local
sudo echo '   echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
sudo echo 'fi' >> /etc/rc.local
sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled

sudo echo deadline > /sys/block/sda/queue/scheduler
sudo echo deadline > /sys/block/sdc/queue/scheduler

##Setup User
sudo groupadd verticadba
sudo usermod -g verticadba dbadmin
sudo chown dbadmin:verticadba /home/dbadmin
sudo chmod 755 /home/dbadmin
sudo chown dbadmin:verticadba /data
sudo echo 'export TZ="America/New_York"' >> /etc/profile

sleep 5

##Install Vertica
sudo /opt/vertica/sbin/install_vertica --accept-eula --license CE --point-to-point --dba-user dbadmin --dba-user-password-disabled --hosts localhost --failure-threshold NONE


##Steps for Test Drive
sudo yum install -y dos2unix
sudo mkdir /data/datafiles
sudo chown dbadmin:verticadba /data/datafiles
sudo mkdir /data/controlfiles
sudo chown dbadmin:verticadba /data/controlfiles
sudo mkdir /tmp/java

sudo echo 1step_DownloadStart >> /home/dbadmin/stepfile
sudo wget -O /tmp/java/dos2unix-6.0.3-4.el7.x86_64.rpm https://s3.amazonaws.com/verticatestdrive/dos2unix-6.0.3-4.el7.x86_64.rpm
sudo wget -O /home/dbadmin/clickstreamAB.tar.gz https://s3.amazonaws.com/verticatestdrive/clickstreamAB.tar.gz
sudo wget -O /home/dbadmin/ML_Function_Schema_Data.tar.gz https://s3.amazonaws.com/verticatestdrive/ML_Function_Schema_Data.tar.gz
sudo wget -O /home/dbadmin/auth.txt https://s3.amazonaws.com/verticatestdrive/auth.txt
sudo wget -O /tmp/java/jdk-8u121-linux-x64.rpm  https://s3.amazonaws.com/verticatestdrive/jdk-8u121-linux-x64.rpm
sudo wget -O /tmp/java/apache-tomcat-8.0.41.tar.gz https://s3.amazonaws.com/verticatestdrive/apache-tomcat-8.0.41.tar.gz
sudo wget -O /tmp/java/editprofile.txt https://s3.amazonaws.com/verticatestdrive/editprofile.txt
#wget -O /tmp/java/Changedbadminpasswd.sh https://s3.amazonaws.com/verticatestdrive/Changedbadminpasswd.sh
sudo wget -O /tmp/java/Changedbadminpasswd.sh https://raw.githubusercontent.com/pradeepts/testRepo/master/Changedbadminpasswd.sh
# wget -O /tmp/java/TestJava.zip https://s3.amazonaws.com/verticatestdrive/TestJava.zip
sudo wget -O /tmp/java/ACME_ABTesting_Dashboard.zip https://s3.amazonaws.com/verticatestdrive/ACME_ABTesting_Dashboard.zip
sudo wget -O /tmp/java/lgx120201.lic https://s3.amazonaws.com/verticatestdrive/lgx120201.lic

sudo echo 2ndstep_DownloadEnd_GunzipStart >> /home/dbadmin/stepfile
sudo gunzip /home/dbadmin/clickstreamAB.tar.gz
sudo gunzip /tmp/java/apache-tomcat-8.0.41.tar.gz
sudo gunzip /home/dbadmin/ML_Function_Schema_Data.tar.gz

sudo echo 3rdstep_GzipEnd_RunRPM >> /home/dbadmin/stepfile      	
sudo rpm -Uvh /tmp/java/jdk-8u121-linux-x64.rpm
# rpm -Uvh /tmp/java/dos2unix-6.0.3-4.el7.x86_64.rpm		  
sudo tar -xvf /tmp/java/apache-tomcat-8.0.41.tar --directory=/opt 
# unzip /tmp/java/TestJava.zip -d /opt/apache-tomcat-8.0.41/webapps/ 	
sudo unzip /tmp/java/ACME_ABTesting_Dashboard.zip -d /opt/apache-tomcat-8.0.41/webapps/ 	
sudo mv /opt/apache-tomcat-8.0.41/webapps/ACME_ABTesting_Dashboard/lgx120201.lic /opt/apache-tomcat-8.0.41/webapps/ACME_ABTesting_Dashboard/lgx120201.lic.old 
# mv /opt/apache-tomcat-8.0.41/webapps/TestJava/lgx120201.lic /opt/apache-tomcat-8.0.41/webapps/TestJava/lgx120201.lic.old
# cp /tmp/java/lgx120201.lic /opt/apache-tomcat-8.0.41/webapps/TestJava/lgx120201.lic
sudo cp /tmp/java/lgx120201.lic /opt/apache-tomcat-8.0.41/webapps/ACME_ABTesting_Dashboard/lgx120201.lic
sudo cat /tmp/java/editprofile.txt | dos2unix  >>/etc/profile
sudo cat /tmp/java/Changedbadminpasswd.sh | dos2unix  >> /tmp/java/Chg.txt
sudo mv /tmp/java/Chg.txt  /tmp/java/Changedbadminpasswd.sh
sudo source /etc/profile

sudo echo 4thstep_InstallVerticaDB >> /home/dbadmin/stepfile 	
sudo -n -H -u dbadmin /opt/vertica/bin/admintools  -t create_db -s localhost -d testdrive -c /data/controlfiles -D /data/datafiles  
sudo -n -H -u dbadmin mkdir /home/dbadmin/TestDrive 		  
sudo -n -H -u dbadmin mkdir /home/dbadmin/TestDrive/ABTesting 		  
sudo -n -H -u dbadmin mkdir /home/dbadmin/TestDrive/MLFunctions

sudo echo 5thstep_Misc >> /home/dbadmin/stepfile 	
sudo cat /home/dbadmin/auth.txt >> /home/dbadmin/.ssh/authorized_keys 	
sudo tar -xvf /home/dbadmin/clickstreamAB.tar  --directory=/home/dbadmin/TestDrive/ABTesting/ 	
sudo tar -xvf /home/dbadmin/ML_Function_Schema_Data.tar --directory=/home/dbadmin/TestDrive/MLFunctions/	
sudo hostname testdrive.localdomain
sudo echo 'testdrive.localdomain' > /etc/hostname
sudo sed 's/1   localhost /1   testdrive.localdomain localhost /' < /etc/hosts > /tmp/java/hosts
sudo cp /etc/hosts /etc/hosts.sav
sudo mv /tmp/java/hosts /etc/hosts
sudo /opt/apache-tomcat-8.0.41/bin/startup.sh
sudo echo End_of_Steps >> /home/dbadmin/stepfile 

sudo echo set_password >> /home/dbadmin/stepfile
sudo chmod +x /tmp/java/Changedbadminpasswd.sh >>/home/dbadmin/stepfile
sudo /tmp/java/Changedbadminpasswd.sh >>/home/dbadmin/stepfile
sudo echo set_password_completed >> /home/dbadmin/stepfile
sudo rm -rf /tmp/java
sudo rm -f /home/dbadmin/clickstreamAB.tar
sudo rm -f /home/dbadmin/ML_Function_Schema_Data.tar
sudo rm -f /home/dbadmin/auth.txt
sudo echo Clean_up_files >> /home/dbadmin/stepfile 
sudo chkconfig --level 12345 verticad  on
sudo sed -i 's/ChallengeResponseAuthentication .*no$/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config

sleep 5

#Firewall add to the vm
sudo yum update -y
sudo systemctl start firewalld
sudo systemctl status firewalld
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5433/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
#sudo reboot
#sleep 10

#restarting the tomcat server
sudo /opt/apache-tomcat-8.0.41/bin/startup.sh

sudo service sshd restart
sudo systemctl stop firewalld
sudo systemctl disable firewalld




