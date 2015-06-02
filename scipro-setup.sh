#
# Remove the user created during install
# We assume it's called 'test'
#
deluser test
rm -rf /home/test

#
# Set a static IP
#

##
## Copy the IP of the domain name to use
##
host scipro-temp

##
## Change the configuration for eth0 to use that static IP
##
nano /etc/network/interfaces

##
## Enable the new configuration
##
ifdown eth0
ifup eth0

##
## Make sure you're using the new IP
##
ifconfig

##
## Make sure it's working
##
ping google.com


#
# Set up ssh access with public key
#

##
## Change the line "PermitRootLogin without-password"
## to "PermitRootLogin yes"
##
nano /etc/ssh/sshd_config
service ssh restart

##
## Connect from the machine with the keypair you want to use
## and paste your public key into /root/.ssh/authorized_keys
##
mkdir /root/.ssh
nano /root/.ssh/authorized_keys

##
## Disconnect and connect again to make sure it works and 
## you're not being prompted for a password
##
logout

##
## Revert your change to sshd_config
##
nano /etc/ssh/sshd_config
service ssh restart


#
# Install pwgen for good passwords
#
apt-get install pwgen


# 
# Generate a mysql password and copy it
#
pwgen -s 30 1


#
# Install the required software, pasting the password you
# just generated when prompted for a mysql root password.
#
apt-get install mysql-server tomcat8 tomcat8-admin apache2


#
# Set up .my.cnf to make sure you don't have to type the
# mysql root password
#

##
## Paste the password into the file
##
nano /root/.my.cnf

##
## Make the file secure
##
chmod 600 /root/.my.cnf

##
## Test that it works. You should be dropped into 
## mysql with no prompts
##
mysql


#
# Configure tomcat
# 

##
## Set the default runtime parameters for 
## the tomcat process
##
nano /etc/default/tomcat8

##
## Create the proper connectors for the communication 
## between apache and tomcat
##
nano /etc/tomcat8/server.xml

## 
## Create a user for the tomcat manager
## 
pwgen 12 1
nano /etc/tomcat8/tomcat-users.xml

##
## Restart tomcat for changes to take effect
##
service tomcat8 restart


#
# Configure apache
#

##
## Set up the ssl certificate configuration
##
nano /etc/apache2/conf-available/ssl.conf
a2enconf ssl
a2enmod ssl

##
## Enable the modules that facilitate communication 
## with tomcat
##
a2enmod proxy proxy_ajp

##
## Create the scipro vhost file, deactivate the default 
## vhost, activate the scipro vhost
##
nano /etc/apache2/sites-available/scipro.conf
a2dissite 000-default.conf
a2ensite scipro.conf

##
## Restart apache for changes to take effect
##
service apache2 restart


#
# It should now be possible to access the tomcat manager
# via http://scipro-temp.dsv.su.se/manager
#


#
# Set up scipro
#

##
## Fix the ownership of a tomcat directory
##
chown -R tomcat8: /var/lib/tomcat8/webapps/ROOT

##
## Install a required mysql connector
## (By copying from your local machine)
##
scp mysql-connector-java-5.1.22.jar scipro-temp:/usr/share/tomcat8/lib/

##
## Create an empty database and user
##
mysql -e "create database scipro"
pwgen -s 30 1
mysql -e "grant all privileges \
          on scipro.* to scipro@localhost \
          identified by '[paste password here]'"

##
## Verify that the database and user work
##
mysql -u scipro -p scipro

##
## Add a mysql connector to tomcat
##
nano /etc/tomcat8/context.xml

##
## Set up a partition for scipro to save files in
##

###
### Create the partition on LVM
###
lvcreate scipro-temp-vg -n srv -L 5G

###
### Create a filesystem in the partition
###
mkfs.ext4 /dev/mapper/scipro--temp--vg-srv

###
### Associate the partition with its mount point
###
echo "/dev/mapper/scipro--temp--vg-srv /srv ext4 defaults 0 0"\
     >> /etc/fstab

###
### Mount the partition
###
mount -a

###
### Create the directory to store the files
###
mkdir /srv/scipro-files

###
### Fix the ownership of the directory
###
chown tomcat8: /srv/scipro-files

###
### Create a symbolic link to the location scipro 
### expects the directory to be in
###
ln -s /srv/scipro-files /scipro-files


##
## Set up a log folder for scipro
##
mkdir /var/log/scipro
chown tomcat8: /var/log/scipro

##
## Upload the war file to the server
## (By copying from your local achine)
##
scp ROOT.war scipro-temp.dsv.su.se:/var/lib/tomcat8/webapps/
