\# Cloud-Native Service Runtime



A Python HTTP service packaged in Docker and deployed to Kubernetes with Helm.



\## Repository layout



\- `service/` — Python application and Dockerfile.

\- `chart/` — Helm chart templates and default values.

\- `lab/` — Part 4 debugging lab, findings and session evidence.

\- `setup.sh` — creates or reuses the kind cluster, installs ingress-nginx, builds and loads the image, and deploys the chart.

\- `ANSWERS.md` — Gateway API migration strategy.



\## Prerequisites



Docker, kind, kubectl, Helm 3 and Bash are required. On Windows, use Git Bash to run `setup.sh`.



\## Run locally



From the repository root:



```bash

docker build -t demo-app:1.0.0 ./service

docker run --rm -d --name demo-app -p 18080:8080 demo-app:1.0.0

```



Test the endpoints (use `curl.exe` in PowerShell):



```bash

curl.exe http://localhost:18080/

curl.exe http://localhost:18080/healthz

```



Stop the local container with:



```powershell

docker rm -f demo-app

```



\## Deploy to kind



Run `./setup.sh` from the repository root using Bash. The script creates or reuses the `demo` kind cluster, installs ingress-nginx if needed, builds and loads `demo-app:1.0.0`, and deploys the Helm release in namespace `demo`. It is designed to be rerun safely.



Verify:



```bash

kubectl rollout status deployment/demo -n demo

kubectl get pods,svc,ingress -n demo

helm status demo -n demo

```



Test using port-forwarding:



```bash

kubectl port-forward svc/demo 18082:80 -n demo

```



In another terminal:



```bash

curl.exe http://localhost:18082/

curl.exe http://localhost:18082/healthz

```



The Ingress host is `demo.local`.



\## Configuration



The application supports `APP\_NAME` and `VERSION` environment variables. In Kubernetes, ConfigMap values are mounted as files under `/etc/demo-config` and read on each request. Updated projected volume files become visible eventually, without restarting the application.



The chart supports overrides for replica count, image, application configuration, ingress host and resources. Example:



```bash

helm template demo ./chart --set replicaCount=3 --set config.appName=override-test

```



\## Resource settings



Default requests are 100m CPU and 64Mi memory; limits are 500m CPU and 128Mi memory. These are modest starting values for this small Python service. Requests support scheduling; limits constrain resource consumption. Production values should be tuned using load tests and observed usage.
