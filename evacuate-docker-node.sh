#!/bin/sh
docker ps -a|grep -v NAME|awk 'BEGIN {FS=OFS=" "}{print $1}'|xargs docker rm -f
docker volume ls|grep -v NAME|awk 'BEGIN {FS=OFS=" "}{print $2}'|xargs docker volume rm

#sudo docker run --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.2.11 http://172.40.20.202:8080/v1/scripts/7327AD6E49B9D80E2A55:1577750400000:qUPuZq7VX03loqCoD4ijtYJjWk  --address eth0