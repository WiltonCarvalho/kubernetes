curl -L# https://github.com/WiltonCarvalho/kubernetes/raw/main/kind-metal-lb-nginx-ingress/kind-config.yaml -o kind-config.yaml

docker network create kind --subnet 172.31.0.0/16
kind create cluster --image kindest/node:v1.30.8 --config kind-config.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
kubectl -n metallb-system get pod --watch

kubectl apply -f https://github.com/WiltonCarvalho/kubernetes/raw/main/kind-metal-lb-nginx-ingress/metallb-config.yaml
kubectl -n metallb-system get ipaddresspools

kubectl run httpd --image httpd:alpine --port 80 --labels app=httpd
kubectl expose pod httpd --name=httpd --type=LoadBalancer --load-balancer-ip=172.31.255.25
curl 172.31.255.25

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --version 4.10.1 \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations.\"metallb\\.universe\\.tf/loadBalancerIPs\"=172.31.255.254

kubectl -n ingress-nginx get pod
curl -I 172.31.255.254/healthz

kubectl create ingress httpd --class=nginx --rule "httpd.example.com/*=httpd:80"
curl http://httpd.example.com --resolve httpd.example.com:80:172.31.255.254

kubectl run registry --image registry:2 --port 5000 --labels app=registry
kubectl expose pod registry --name=registry --type=LoadBalancer --port=80 --target-port=5000 --load-balancer-ip=172.31.255.201

kubectl get svc

curl -i http://registry.172.31.255.201.sslip.io

skopeo copy --dest-tls-verify=false docker://nginx:alpine docker://registry.172.31.255.201.sslip.io/nginx:alpine

kubectl run nginx --image registry.172.31.255.201.sslip.io/nginx:alpine --port 80 --labels app=nginx
kubectl expose pod nginx --name=nginx --type=LoadBalancer
