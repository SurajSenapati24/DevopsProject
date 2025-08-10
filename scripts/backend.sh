#!/bin/bash
set -e

DOCKER_USERNAME="$1"

sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

echo "Pulling backend image..."
sudo docker pull ${DOCKER_USERNAME}/profile-app-backend:latest

echo "Starting backend..."
sudo docker run -d --name profile-backend \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=profile_db \
  -e MYSQL_USER=user \
  -e MYSQL_PASSWORD=password \
  -v mysql_data:/var/lib/mysql \
  ${DOCKER_USERNAME}/profile-app-backend:latest

sleep 15
sudo docker ps
