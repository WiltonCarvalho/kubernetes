sudo curl -fsSL https://github.com/kubernetes-sigs/kind/releases/download/v0.27.0/kind-linux-amd64 -o /usr/local/bin/kind
sudo chmod +x /usr/local/bin/kind

curl -L# https://github.com/WiltonCarvalho/kubernetes/raw/main/kind-metal-lb-nginx-ingress/kind-config.yaml -o ~/kind-config.yaml

kind delete cluster
docker network rm kind
docker network create kind --subnet 172.31.0.0/16
kind create cluster --image kindest/node:v1.30.8 --config ~/kind-config.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
kubectl -n metallb-system get pod --watch

kubectl apply -f https://github.com/WiltonCarvalho/kubernetes/raw/main/kind-metal-lb-nginx-ingress/metallb-config.yaml
kubectl -n metallb-system get ipaddresspools

kubectl run httpd --image httpd:alpine --port 80 --labels app=httpd
kubectl wait --for=condition=ready pod -l app=httpd
kubectl expose pod httpd --name=httpd --type=LoadBalancer --load-balancer-ip=172.31.255.25 --labels app=httpd
sleep 3
curl 172.31.255.25

openssl req -x509 -nodes -days 3650 -new -subj "/CN=wiltoncarvalho.com" \
  -newkey rsa:2048 -keyout /tmp/key.pem -out /tmp/cert.pem

kubectl create secret tls default-ssl-secret \
  --key /tmp/key.pem --cert /tmp/cert.pem --namespace default

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --version 4.12.1 \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations.\"metallb\\.universe\\.tf/loadBalancerIPs\"=172.31.255.254 \
  --set controller.extraArgs.default-ssl-certificate='default/default-ssl-secret'

kubectl -n ingress-nginx get pod
curl -I 172.31.255.254/healthz

kubectl create ingress httpd --class=nginx --rule "httpd.wiltoncarvalho.com/*=httpd:80"
sleep 3
curl http://httpd.wiltoncarvalho.com --resolve httpd.wiltoncarvalho.com:80:172.31.255.254
curl https://httpd.wiltoncarvalho.com --resolve httpd.wiltoncarvalho.com:443:172.31.255.254 -k

kubectl run registry --image registry:2 --port 5000 --labels app=registry
kubectl expose pod registry --name=registry --type=LoadBalancer --port=80 --target-port=5000 --load-balancer-ip=172.31.255.201

kubectl get svc

curl -i http://registry.172.31.255.201.sslip.io

skopeo copy --dest-tls-verify=false docker://nginx:alpine docker://registry.172.31.255.201.sslip.io/nginx:alpine

kubectl run nginx --image registry.172.31.255.201.sslip.io/nginx:alpine --port 80 --labels app=nginx
kubectl expose pod nginx --name=nginx --type=LoadBalancer
