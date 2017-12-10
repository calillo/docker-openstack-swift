FROM ubuntu:16.04

MAINTAINER calillo

RUN apt-get update
RUN apt-get -y dist-upgrade
RUN apt-get install -y net-tools less vim iputils-ping telnet
RUN apt-get install -y swift swift-account swift-container swift-object xfsprogs rsync \
                       swift-proxy python-swiftclient python-keystonemiddleware memcached python-memcache rsyslog

ADD paco/account-server.conf    /etc/swift/account-server.conf
ADD paco/container-server.conf  /etc/swift/container-server.conf
ADD paco/object-server.conf     /etc/swift/object-server.conf
ADD paco/proxy-server.conf	/etc/swift/proxy-server.conf
ADD paco/swift.conf             /etc/swift/swift.conf
ADD paco/rsyncd.conf            /etc/rsyncd.conf
ADD paco/rsync                  /etc/default/rsync
#ADD paco/0-swift.conf           /etc/rsyslog.d/0-swift.conf
ADD paco/start_p.sh		/usr/local/bin/start_p.sh
ADD paco/start_aco.sh           /usr/local/bin/start_aco.sh

RUN chmod 755 /usr/local/bin/*.sh
RUN mkdir /srv/swift

EXPOSE 8080
EXPOSE 6000 6001 6002

#CMD /usr/local/bin/start_p.sh

