#!/bin/bash

IMAGE_NAME="openprescribing-template"
IMAGE_REPO="ghcr.io/bennettoxford/$IMAGE_NAME:latest"
IMAGE_URL="https://github.com/orgs/bennettoxford/packages/container/package/$IMAGE_NAME"

underline='\033[4m'
underline_off='\033[24m'

# Prompt for GitHub username
read -p "Enter your GitHub username: " GH_USERNAME

# Prompt for GitHub Personal Access Token (PAT)
read -s -p "Enter your GitHub Personal Access Token (PAT): " GH_PAT
echo

# Login to GHCR
echo "$GH_PAT" | docker login ghcr.io -u "$GH_USERNAME" --password-stdin

# Build the Docker image
docker build -t "$IMAGE_REPO" .

# Push the Docker image to GHCR
docker push "$IMAGE_REPO"

echo
echo -e "You can view the new image at: ${underline}$IMAGE_URL${underline_off}"
echo