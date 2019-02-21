# docker-openstack-swift

## docker command

build image
```bash
docker build -t calillo/docker-openstack-swift:latest docker-openstack-swift
```

run bash on container
```bash
docker exec -it proxy /bin/bash
```

stop/remove all container
```bash
docker rm $(docker ps -a -q)
```

exit container
```bash
CTRL-P CTRL-Q
```

## manual docker startup

create volume
```bash
docker volume create --name my-swift-conf
```

start containers
```bash
docker run -v my-swift-conf:/srv/swift -p 8080:8080 -h proxy --name proxy -it -d calillo/docker-openstack-swift /usr/local/bin/start_p.sh
docker run --privileged -v my-swift-conf:/srv/swift -h node1 --name node1 -it -d calillo/docker-openstack-swift /usr/local/bin/start_aco.sh
docker run --privileged -v my-swift-conf:/srv/swift -h node2 --name node2 -it -d calillo/docker-openstack-swift /usr/local/bin/start_aco.sh
```

## auto docker-compose startup

```bash
docker-compose -p swift up -d
```

scale up another node
```bash
docker-compose -p swift up --scale node=2 -d
```

stop/remove all container
```bash
docker-compose -p swift down --volumes
```

## swift test command

stat
```bash
swift -A http://127.0.0.1:8080/auth/v1.0 -U test:tester -K testing stat
```

upload
```bash
swift -A http://127.0.0.1:8080/auth/v1.0 -U test:tester -K testing upload container file.txt
```
