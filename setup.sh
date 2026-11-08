#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="demo"
KUBE_CONTEXT="kind-demo"
IMAGE="demo-app:1.0.0"
INGRESS_MANIFEST="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml"

for cmd in docker kind kubectl helm; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $cmd" >&2
    exit 1
  fi
done

docker info >/dev/null

# Create the cluster only when it does not already exist.
if ! kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  echo "Creating kind cluster: $CLUSTER_NAME"

  kind_config="$(mktemp)"
  cat > "$kind_config" <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
EOF

  kind create cluster --name "$CLUSTER_NAME" --config "$kind_config"
  rm -f "$kind_config"
else
  echo "Reusing existing kind cluster: $CLUSTER_NAME"
fi

kubectl --context "$KUBE_CONTEXT" cluster-info >/dev/null

# Install ingress-nginx only when its controller deployment is absent.
if ! kubectl --context "$KUBE_CONTEXT" \
    get deployment ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; then
  echo "Installing ingress-nginx"
  kubectl --context "$KUBE_CONTEXT" apply -f "$INGRESS_MANIFEST"
else
  echo "Reusing existing ingress-nginx controller"
fi

kubectl --context "$KUBE_CONTEXT" \
  wait --namespace ingress-nginx \
  --for=condition=Available deployment/ingress-nginx-controller \
  --timeout=180s

# Build the service image and make it available inside kind.
echo "Building application image"
docker build -t "$IMAGE" ./service

echo "Loading image into kind"
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

# Deploy or update the application in the required namespace.
echo "Deploying Helm release"
helm upgrade --install demo ./chart \
  --kube-context "$KUBE_CONTEXT" \
  --namespace demo \
  --create-namespace \
  --wait \
  --timeout 5m

echo "Setup completed successfully."
