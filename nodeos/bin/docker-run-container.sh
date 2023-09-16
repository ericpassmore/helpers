#!/usr/bin/env bash

docker run -d -it --name ${1:-leap-v4.0} -v ${HOME}:/docker-mount --entrypoint /bin/bash leap-base-04
# docker exec -it leap-v4.0 /bin/bash
