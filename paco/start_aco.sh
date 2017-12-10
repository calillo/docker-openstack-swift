#!/bin/bash

#
# Make the rings if they don't exist already
#

# These can be set with docker run -e VARIABLE=X at runtime
#SWIFT_PART_POWER=${SWIFT_PART_POWER:-7}
#SWIFT_PART_HOURS=${SWIFT_PART_HOURS:-1}
#SWIFT_REPLICAS=${SWIFT_REPLICAS:-1}
#SWIFT_OWORKERS=${SWIFT_OWORKERS:-8}
SWIFT_DEVICE=${SWIFT_DEVICE:-d1:d2}
#SWIFT_SCP_COPY=${SWIFT_SCP_COPY:-root@192.168.0.171:~/files:kevin}

if [ -e /srv/swift/account.builder ]; then
	echo "Ring files already exist in /srv, copying them to /etc/swift..."
	cp -p /srv/swift/*.builder /etc/swift/
	cp -p /srv/swift/*.gz /etc/swift/
fi

# This comes from a volume, so need to chown it here, not sure of a better way
# to get it owned by Swift.
mkdir /srv/node
chown -R swift:swift /srv

cd /etc/swift

#for device  in $(echo $SWIFT_DEVICE | tr ":" "\n"); do
#	mkdir -p /srv/node/$device
#	mount /dev/$device /srv/node/$device -t ext4 -o noatime,nodiratime,nobarrier,user_xattr
#done
for device  in $(echo $SWIFT_DEVICE | tr ":" "\n"); do
	mkdir -p /srv/node/$device
done

chown -R swift:swift /srv


#SCPPASSWORD=`sed "s/.*://g" <<< $SWIFT_SCP_COPY`
#SCPPATH=`sed "s/.*:\(.*\):.*/\1/" <<< $SWIFT_SCP_COPY`
#SCPHOST=`sed "s/:.*//g" <<< $SWIFT_SCP_COPY`

#sshpass -p $SCPPASSWORD scp -r -o StrictHostKeyChecking=no  $SCPHOST:$SCPPATH/*.gz .

chown -R swift:swift /etc/swift

# the storage_url_scheme should be set to https. So if this var isn't empty, set
# the default storage url to https.
if [ ! -z "${SWIFT_STORAGE_URL_SCHEME}" ]; then
	echo "Setting default_storage_scheme to https in proxy-server.conf..."
	sed -i -e "s/storage_url_scheme = default/storage_url_scheme = https/g" /etc/swift/proxy-server.conf
	grep "storage_url_scheme" /etc/swift/proxy-server.conf
fi

if [ ! -z "${SWIFT_SET_PASSWORDS}" ]; then
	echo "Setting passwords in /etc/swift/proxy-server.conf"
	PASS=`pwgen 12 1`
	sed -i -e "s/user_admin_admin = admin .admin .reseller_admin/user_admin_admin = $PASS .admin .reseller_admin/g" /etc/swift/proxy-server.conf
	sed -i -e "s/user_test_tester = testing .admin/user_test_tester = $PASS .admin/g" /etc/swift/proxy-server.conf
	sed -i -e "s/user_test2_tester2 = testing2 .admin/user_test2_tester2 = $PASS .admin/g" /etc/swift/proxy-server.conf
	sed -i -e "s/user_test_tester3 = testing3/user_test_tester3 = $PASS/g" /etc/swift/proxy-server.conf
	grep "user_test" /etc/swift/proxy-server.conf
fi

# Set the number of object workers on fly
#sed -i "s/workers.*/workers = $SWIFT_OWORKERS/g" /etc/swift/object-server.conf

# Start supervisord
#echo "Starting supervisord..."
#/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

service memcached start
service rsyslog start
service rsync start

swift-init start account
swift-init start container
swift-init start object

swift-init account-auditor start
swift-init account-replicator start
swift-init account-reaper start

swift-init container-auditor start
swift-init container-replicator start
swift-init container-sync start
swift-init container-updater start

swift-init object-auditor start
swift-init object-replicator start
swift-init object-updater start
#
# Tail the log file for "docker log $CONTAINER_ID"
#

# sleep waiting for rsyslog to come up under supervisord
sleep 3

echo "Starting to tail /var/log/syslog...(hit ctrl-c if you are starting the container in a bash shell)"

#tail -n 0 -f /var/log/syslog