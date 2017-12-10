# docker-openstack-swift

create volume
```bash
docker volume create --name my-swift-conf
```

build image
```bash
docker build -t calillo/docker-openstack-swift:latest docker-openstack-swift
```

3 times
```bash
docker run -v my-swift-conf:/srv/swift -it [id] /bin/bash
```

start swift
```bash
/usr/local/bin/start_p.sh
/usr/local/bin/start_aco.sh
/usr/local/bin/start_aco.sh
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
