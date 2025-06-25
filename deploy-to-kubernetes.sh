#!/bin/bash
set -e

# Create the namespace if it doesn't exist
echo "Creating bootcamp namespace..."
kubectl create namespace bootcamp --dry-run=client -o yaml | kubectl apply -f -

# Create the GitHub token secret
echo "Creating GitHub token secret..."
# Note: You'll need to replace this with your actual base64-encoded token
# You can generate it with: echo -n "your-github-token" | base64
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GH_TOKEN environment variable is not set"
  echo "Please set it with: export GH_TOKEN=your-github-token"
  exit 1
fi

# Create the secret using the environment variable
kubectl create secret generic github-credentials \
  --namespace=bootcamp \
  --from-literal=token="$GH_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

# Apply the deployments
echo "Applying the Nexus deployment..."
kubectl apply -f deployment-nexus.yaml

echo "Applying the GitHub Actions runner deployment..."
kubectl apply -f deployment-gha.yaml

# Check the deployment status
echo "Checking deployment status..."
kubectl get deployments -n bootcamp
kubectl get pods -n bootcamp
