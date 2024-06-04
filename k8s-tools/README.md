### Docker and Kind ###
```
docker info
kind --version
```

### KinD with Metal LB ###
```
docker network create kind --subnet 172.31.0.0/16
kind create cluster --image kindest/node:v1.27.10 --config k8s-tools/1-kind/kind-config.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
kubectl -n metallb-system get pod --watch

kubectl apply -f k8s-tools/1-kind/metallb-config.yaml
kubectl -n metallb-system get ipaddresspools

kubectl run httpd --image httpd:alpine --port 80 --labels app=httpd
kubectl expose pod httpd --name=httpd --type=LoadBalancer --load-balancer-ip=172.31.255.25
curl 172.31.255.25
```
### Terraform Modules
- cd k8s-tools
- terraform init
- terraform apply -target module.ingress --auto-approve
- terraform apply -target module.metrics-server --auto-approve
- terraform apply -target module.kube-prometheus-stack --auto-approve
- terraform apply -target module.prometheus-adapter --auto-approve
- terraform apply -target module.loki --auto-approve
- terraform apply -target module.promtail --auto-approve
- terraform apply -target module.tempo --auto-approve
- terraform apply -target module.otel --auto-approve
- terraform apply -target module.argocd --auto-approve


### Prometheus Port Forward ###
```
kubectl -n monitoring port-forward services/prometheus-operated 9090:9090
```

### Prometheus ###
```
firefox localhost:9090
```

### Grafana Ingress ###
```
firefox https://172.31.255.254.sslip.io/grafana
```

### ArgoCD Admin Token ###
```
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### ArgoCD Ingress ###
```
firefox https://172.31.255.254.sslip.io/argocd
```
