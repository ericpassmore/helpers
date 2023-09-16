#!/usr/bin/env bash

docker build --tag leap-base:04 --ulimit nofile=1024:1024 - < ../docker/DockerFileNodeos
