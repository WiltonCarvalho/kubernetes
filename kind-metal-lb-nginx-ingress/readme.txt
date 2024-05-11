curl -L# https://github.com/WiltonCarvalho/kubernetes/raw/main/kind-metal-lb-nginx-ingress/kind-config.yaml -o kind-config.yaml

docker network create kind --subnet 172.31.0.0/16
kind create cluster --image kindest/node:v1.27.10 --config kind-config.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
kubectl -n metallb-system get pod --watch

kubectl apply -f https://github.com/WiltonCarvalho/kubernetes/raw/main/kind-metal-lb-nginx-ingress/metallb-config.yaml
kubectl -n metallb-system get ipaddresspools

kubectl run httpd --image httpd:alpine --port 80 --labels app=httpd
kubectl expose pod httpd --name=httpd --type=LoadBalancer

kubectl run nginx --image nginx:alpine --port 80 --labels app=nginx
kubectl expose pod nginx --name=nginx --type=LoadBalancer

kubectl run registry --image registry:2 --port 5000 --labels app=registry
kubectl expose pod registry --name=registry --type=LoadBalancer --port=80 --target-port=5000 --load-balancer-ip=172.31.255.201

curl -i http://registry.172.31.255.201.sslip.io

kubectl get svc