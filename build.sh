#!/bin/bash

# Define services and their Dockerfile locations
declare -A services
services["code-server-python"]="./Dockerfile"


# Loop through the services and build them
for service in "${!services[@]}"; do
    docker buildx build --platform linux/arm64 --build-arg ARCH=arm64 -t 192.168.1.1:5000/$service:latest -f ${services[$service]} . --push --no-cache
    if [ $? -ne 0 ]; then
        echo "Error building $service"
        exit 1
    fi
done
