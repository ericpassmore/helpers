#!/usr/bin/env bash

docker build --tag leap-base:05 --ulimit nofile=1024:1024 - < ../docker/DockerFileNodeos
