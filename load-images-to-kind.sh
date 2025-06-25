#!/bin/bash
set -e

# Build and tag the images
echo "Building and tagging the runner image..."
docker build -t nexus-docker-runner:v1.0.0 ./runner

echo "Building and tagging the nexus image..."
docker build -t nexus-docker-nexus:v1.0.0 ./nexus

# Load the images into Kind
echo "Loading the runner image into Kind..."
kind load docker-image nexus-docker-runner:v1.0.0

echo "Loading the nexus image into Kind..."
kind load docker-image nexus-docker-nexus:v1.0.0

echo "Images have been successfully loaded into Kind!"
