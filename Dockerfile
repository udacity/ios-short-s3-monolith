FROM ibmcom/swift-ubuntu:3.1

MAINTAINER Jarrod Parkes <jarrod@udacity.com>

RUN apt-get update; \
    apt-get dist-upgrade -y; \
    apt-get install -y apt-utils uuid-dev libssl-dev software-properties-common; \
    add-apt-repository -y ppa:0k53d-karl-f830m/openssl; \
    apt-get update; \
    apt-get install -y openssl

WORKDIR /app
