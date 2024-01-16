#!/usr/bin/env bash

docker run -d -it --name ${1:-leap-vIF} -v ${HOME}:/docker-mount --entrypoint /bin/bash leap-base:05
# docker exec -it leap-vIF /bin/bash
