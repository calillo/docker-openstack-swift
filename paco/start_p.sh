#!/bin/bash

# these can be set with docker run -e VARIABLE=X at runtime
SWIFT_PART_POWER=${SWIFT_PART_POWER:-7}
SWIFT_PART_HOURS=${SWIFT_PART_HOURS:-1}
SWIFT_REPLICAS=${SWIFT_REPLICAS:-3}

#SWIFT_OBJECT_NODES=${SWIFT_OBJECT_NODES:-172.17.0.3:6000:d1;172.17.0.3:6000:d2;172.17.0.4:6000:d1;172.17.0.4:6000:d2}

# clean ring volume
if [ -e /srv/swift/account.builder ]; then
    rm -rf /srv/swift/*
fi

# create initial rings
chown -R swift:swift /srv
cd /etc/swift

echo "Ring files, creating them..."
swift-ring-builder object.builder create ${SWIFT_PART_POWER} ${SWIFT_REPLICAS} ${SWIFT_PART_HOURS}
swift-ring-builder container.builder create ${SWIFT_PART_POWER} ${SWIFT_REPLICAS} ${SWIFT_PART_HOURS}
swift-ring-builder account.builder create ${SWIFT_PART_POWER} ${SWIFT_REPLICAS} ${SWIFT_PART_HOURS}

#for SWIFT_OBJECT_NODE  in $(echo $SWIFT_OBJECT_NODES | tr ";" "\n"); do
#
#    # Calculate port
#    SWIFT_OBJECT_DEVICE=`sed "s/.*://g" <<< $SWIFT_OBJECT_NODE`
#    SWFIT_OBJECT_PORT=`sed "s/.*:\(.*\):.*/\1/" <<< $SWIFT_OBJECT_NODE`
#    SWIFT_OBJECT_NODE=`sed "s/:.*//g" <<< $SWIFT_OBJECT_NODE`
#  
#    # add files
#    swift-ring-builder object.builder add r1z1-${SWIFT_OBJECT_NODE}:$SWFIT_OBJECT_PORT/$SWIFT_OBJECT_DEVICE 1
#    swift-ring-builder container.builder add r1z1-${SWIFT_OBJECT_NODE}:$(($SWFIT_OBJECT_PORT + 1))/$SWIFT_OBJECT_DEVICE 1
#    swift-ring-builder account.builder add r1z1-${SWIFT_OBJECT_NODE}:$(($SWFIT_OBJECT_PORT + 2))/$SWIFT_OBJECT_DEVICE 1
#
#done
#swift-ring-builder object.builder rebalance
#swift-ring-builder container.builder rebalance
#swift-ring-builder account.builder rebalance

# backup these for later use
echo "Copying ring files to /srv to save them if it's a docker volume..."
chown swift:swift /etc/swift/*
#cp -p *.gz /srv/swift
cp -p *.builder /srv/swift

# wait until one node come up
while [ ! -f /srv/swift/account.ring.gz ]
do
    sleep 2
done
echo "Ring files already exist in /srv, copying them to /etc/swift..."
cp -p /srv/swift/*.builder /etc/swift/
cp -p /srv/swift/*.gz /etc/swift/

# start services
service memcached start
service rsyslog start
swift-init start proxy

# sleep waiting for rsyslog to come up under supervisord
sleep 3

echo "Starting to tail /var/log/syslog...(hit ctrl-c if you are starting the container in a bash shell)"

tail -n 0 -f /var/log/syslog
