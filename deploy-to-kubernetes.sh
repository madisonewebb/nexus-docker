#!/bin/bash
set -e

# Apply the deployments
echo "Applying the Nexus deployment..."
kubectl apply -f deployment-nexus.yaml

echo "Applying the GitHub Actions runner deployment..."
kubectl apply -f deployment-gha.yaml

echo "Applying the service..."
kubectl apply -f service-nexus.yaml

# Check the deployment status
echo "Checking deployment status..."
kubectl get deployments -n bootcamp
kubectl get pods -n bootcamp
kubectl get services -n bootcamp
