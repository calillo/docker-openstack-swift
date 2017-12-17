# docker-openstack-swift

create volume
```bash
docker volume create --name my-swift-conf
```

build image
```bash
docker build -t calillo/docker-openstack-swift:latest docker-openstack-swift
```

start containers
```bash
docker run -v my-swift-conf:/srv/swift -p 8080:8080 -h proxy --name proxy -it -d calillo/docker-openstack-swift /usr/local/bin/start_p.sh
docker run --privileged -v my-swift-conf:/srv/swift -h node1 --name node1 -it -d calillo/docker-openstack-swift /usr/local/bin/start_aco.sh
docker run --privileged -v my-swift-conf:/srv/swift -h node2 --name node2 -it -d calillo/docker-openstack-swift /usr/local/bin/start_aco.sh
```

run bash on container
```bash
docker exec -it proxy /bin/bash
```

start swift
```bash
/usr/local/bin/start_p.sh
/usr/local/bin/start_aco.sh
/usr/local/bin/start_aco.sh
```

stop/remove all container
```bash
docker rm $(docker ps -a -q)
```

exit container
```bash
CTRL-P CTRL-Q
```

stat
```bash
swift -A http://127.0.0.1:8080/auth/v1.0 -U test:tester -K testing stat
```

upload
```bash
swift -A http://127.0.0.1:8080/auth/v1.0 -U test:tester -K testing upload container file.txt
```
