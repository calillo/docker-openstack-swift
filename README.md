# docker-openstack-swift

docker volume create --name my-swift-conf

docker build -t calillo/ubuntu-swift:latest ubuntu-swift

docker run -v my-swift-conf:/srv/swift -it id /bin/bash
