#!/usr/bin/env bash

set -euo pipefail

MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-minikube}"
K8S_NAMESPACE="${K8S_NAMESPACE:-kidney-ct}"
IMAGE="${IMAGE:-atul1695/kidney-ct-classifier:latest}"

command -v minikube >/dev/null 2>&1 || { echo "minikube is not installed."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker is not installed."; exit 1; }

minikube -p "$MINIKUBE_PROFILE" status >/dev/null
kubectl config use-context "$MINIKUBE_PROFILE" >/dev/null

docker pull "$IMAGE"
minikube -p "$MINIKUBE_PROFILE" image load "$IMAGE"

kubectl create namespace "$K8S_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n "$K8S_NAMESPACE" -f k8s/service.yaml
kubectl apply -n "$K8S_NAMESPACE" -f k8s/deployment.yaml
kubectl set image deployment/kidney-ct-classifier classifier="$IMAGE" -n "$K8S_NAMESPACE"
kubectl rollout status deployment/kidney-ct-classifier -n "$K8S_NAMESPACE" --timeout=300s

echo "Service URL:"
minikube service kidney-ct-classifier-svc -n "$K8S_NAMESPACE" --url