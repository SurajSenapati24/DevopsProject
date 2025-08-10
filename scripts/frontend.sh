#!/bin/bash
set -e

BACKEND_IP="$1"
DOCKER_USERNAME="$2"

sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

echo "Pulling frontend image..."
sudo docker pull ${DOCKER_USERNAME}/profile-app-frontend:latest

echo "Starting frontend..."
sudo docker run -d --name profile-frontend \
  -p 80:3000 -p 3000:3000 \
  -e DB_HOST=$BACKEND_IP \
  -e DB_USER=appuser \
  -e DB_PASS=apppassword \
  -e DB_NAME=profile_db \
  ${DOCKER_USERNAME}/profile-app-frontend:latest

sleep 8
sudo docker ps
curl -f http://localhost:3000/health && echo "Frontend Healthy"
