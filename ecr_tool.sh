#!/bin/bash

# Command-line tool to build and push Docker images to Amazon ECR based on ecr.yaml configuration

# === Constants ===
CONFIG_FILE="ecr.yaml"

# === Function to Check YAML Configuration File ===
check_config_file() {
    if [ ! -f $CONFIG_FILE ]; then
        echo "Error: Configuration file '$CONFIG_FILE' not found in the project root."
        exit 1
    fi
}

# === Function to Parse YAML Configuration ===
parse_yaml() {
    echo "Parsing configuration file '$CONFIG_FILE'..."
    AWS_REGION=$(grep -E '^AWS_REGION:' $CONFIG_FILE | awk '{print $2}')
    REPOSITORY_NAME=$(grep -E '^REPOSITORY_NAME:' $CONFIG_FILE | awk '{print $2}')
    IMAGE_TAG=$(grep -E '^IMAGE_TAG:' $CONFIG_FILE | awk '{print $2}')
    DOCKER_REGISTRY=$(grep -E '^DOCKER_REGISTRY:' $CONFIG_FILE | awk '{print $2}')

    # Ensure required variables are set
    if [ -z "$AWS_REGION" ] || [ -z "$REPOSITORY_NAME" ] || [ -z "$IMAGE_TAG" ] || [ -z "$DOCKER_REGISTRY" ]; then
        echo "Error: Missing required configuration in '$CONFIG_FILE'."
        exit 1
    fi
}

# === Function to Authenticate Docker with ECR ===
ecr_authenticate() {
    echo "Authenticating Docker with Amazon ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $DOCKER_REGISTRY
    if [ $? -ne 0 ]; then
        echo "Error: Docker authentication failed. Ensure AWS CLI is configured and ECR permissions are granted."
        exit 1
    fi
    echo "Authentication successful."
}

# === Function to Build Docker Image ===
build_image() {
    echo "Building Docker image from current directory..."
    docker buildx build --platform linux/arm/v7 -t $REPOSITORY_NAME:$IMAGE_TAG .
    if [ $? -ne 0 ]; then
        echo "Error: Docker image build failed."
        exit 1
    fi
    echo "Docker image built successfully: $REPOSITORY_NAME:$IMAGE_TAG"
}

# === Function to Tag Docker Image ===
tag_image() {
    echo "Tagging Docker image for ECR..."
    docker tag $REPOSITORY_NAME:$IMAGE_TAG $DOCKER_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG
    if [ $? -ne 0 ]; then
        echo "Error: Failed to tag Docker image."
        exit 1
    fi
    echo "Image tagged successfully: $DOCKER_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG"
}

# === Function to Push Docker Image to ECR ===
push_image() {
    echo "Pushing Docker image to Amazon ECR..."
    docker push $DOCKER_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG
    if [ $? -ne 0 ]; then
        echo "Error: Failed to push Docker image to ECR."
        exit 1
    fi
    echo "Docker image pushed successfully: $DOCKER_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG"
}

# === Function to Ensure ECR Repository Exists ===
ensure_ecr_repository() {
    echo "Ensuring ECR repository exists: $REPOSITORY_NAME"
    aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $AWS_REGION > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Repository not found. Creating ECR repository: $REPOSITORY_NAME"
        aws ecr create-repository --repository-name $REPOSITORY_NAME --region $AWS_REGION
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create ECR repository."
            exit 1
        fi
        echo "ECR repository created successfully: $REPOSITORY_NAME"
    else
        echo "ECR repository exists: $REPOSITORY_NAME"
    fi
}

# === Main Execution ===
main() {
    echo "Starting Docker build and push process..."

    # Check configuration file
    check_config_file

    # Parse configuration file
    parse_yaml

    # Authenticate Docker with ECR
    ecr_authenticate

    # Ensure the ECR repository exists
    ensure_ecr_repository

    # Build the Docker image
    build_image

    # Tag the Docker image
    tag_image

    # Push the Docker image to ECR
    push_image

    echo "Docker build and push process completed successfully."
}

# Run the script
main
