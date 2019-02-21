#!/bin/bash

SWIFT_NODE=$(hostname --ip-address)
SWIFT_PORT=6000
# these can be set with docker run -e VARIABLE=X at runtime
SWIFT_DISK_SIZE=${SWIFT_DISK_SIZE:-20MB}
SWIFT_DEVICE=${SWIFT_DEVICE:-d1:d2:d3}

# wait until proxy create ring
while [ ! -f /srv/swift/account.builder ]
do
    sleep 5
done
echo "Ring files already exist in /srv, copying them to /etc/swift..."
cp -p /srv/swift/*.builder /etc/swift/
cp -p /srv/swift/*.gz /etc/swift/

# create disk devices
mkdir /srv/disk
mkdir /srv/node
chown -R swift:swift /srv
#for device  in $(echo $SWIFT_DEVICE | tr ":" "\n"); do
#	mkdir -p /srv/node/$device
#	mount /dev/$device /srv/node/$device -t ext4 -o noatime,nodiratime,nobarrier,user_xattr
#done
for device in $(echo $SWIFT_DEVICE | tr ":" "\n"); do
    truncate -s $SWIFT_DISK_SIZE /srv/disk/$device
    mkfs.xfs /srv/disk/$device	
    mkdir -p /srv/node/$device
    echo "/srv/disk/$device /srv/node/$device xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
    mount /srv/disk/$device
done
chown -R swift:swift /srv

# add node to the ring
cd /etc/swift
for device in $(echo $SWIFT_DEVICE | tr ":" "\n"); do
    # add files
    swift-ring-builder object.builder add r1z1-${SWIFT_NODE}:$SWIFT_PORT/$device 1
    swift-ring-builder container.builder add r1z1-${SWIFT_NODE}:$(($SWIFT_PORT + 1))/$device 1
    swift-ring-builder account.builder add r1z1-${SWIFT_NODE}:$(($SWIFT_PORT + 2))/$device 1

done
swift-ring-builder object.builder rebalance --force
swift-ring-builder container.builder rebalance --force
swift-ring-builder account.builder rebalance --force

# backup these for later use
echo "Copying ring files to /srv to save them if it's a docker volume..."
chown -R swift:swift /etc/swift/*
cp -p *.gz /srv/swift
cp -p *.builder /srv/swift

# start services
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

# sleep waiting for rsyslog to come up under supervisord
sleep 3

echo "Starting to tail /var/log/syslog...(hit ctrl-c if you are starting the container in a bash shell)"

tail -n 0 -f /var/log/syslog
