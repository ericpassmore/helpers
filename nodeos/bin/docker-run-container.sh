#!/usr/bin/env bash

docker run -d -it --name ${1:-spring-v1} -v ${HOME}:/docker-mount --entrypoint /bin/bash spring-base:01
# docker exec -it spring-v1 /bin/bash
