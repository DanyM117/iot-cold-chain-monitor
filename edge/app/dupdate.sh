#!/bin/bash

# Pulls the latest image from ECR and restarts this app's stack. Scoped to
# this project only - it does NOT touch any other container/image on the
# host (the original version did a host-wide `docker rm -f $(docker ps -aq)`
# / `docker rmi -f $(docker images -q)`, which would nuke unrelated
# workloads sharing the same box).

cd "$(dirname "$0")" || exit 1

if [ ! -f .env ]; then
	echo "Error: .env file not found"
	exit 1
fi
source .env

function ecr_login(){
	echo "Authenticating with ECR..."
	if ! aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"; then
		echo "Error: failed to authenticate with ECR"
		return 1
	fi
	echo "ECR authentication succeeded"
	return 0
}

function composer(){
	echo "Stopping this project's containers (if running)..."
	docker compose down

	echo "Pulling latest image from ECR..."
	if ! docker compose pull; then
		echo "Warning: failed to pull image, falling back to local cache"
	fi

	if ! docker compose up -d; then
		echo "Error: failed to bring the stack up"
		return 1
	fi
	echo "Stack is running"
	return 0
}

if ! ecr_login; then
	echo "Warning: continuing without ECR auth (image must already be cached locally)"
fi

composer
