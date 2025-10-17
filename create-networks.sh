#!/bin/bash

echo "I'm creating networks for docker"

docker network create traefik-public --driver bridge --subnet=172.20.0.0/16
docker network create authentik-internal --driver bridge --subnet=172.21.0.0/16 --internal
docker network create services-internal --driver bridge --subnet=172.22.0.0/16 --internal
docker network create database-internal --driver bridge --subnet=172.23.0.0/16 --internal
docker network create tailscale-internal --driver bridge --subnet=172.24.0.0/16 --internal



echo "Done!"
echo ""
echo "Network available"
docker network ls | grep -E "(traefik-public|authentik-internal|services-internal|database-internal)"