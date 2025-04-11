KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable-1.31.txt)
sudo curl -fsSL https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
curl -fsSL https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz | sudo tar zxvf - -C "/usr/local/bin" linux-amd64/helm --strip-components 1

KUBECTX_VERSION=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
sudo curl -fsSL https://github.com/ahmetb/kubectx/releases/download/$KUBECTX_VERSION/kubectx -o /usr/local/bin/kubectx
sudo chmod +x /usr/local/bin/kubectx

YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
sudo curl -fsSL https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/yq_linux_amd64 -o /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq

KUSTOMIZE_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION#kustomize/}_linux_amd64.tar.gz | sudo tar zxvf - -C "/usr/local/bin"

cat <<'EOF'>> ~/.bashrc
test -x /usr/local/bin/kubectl && source <(kubectl completion bash)
test -x /usr/local/bin/kubectl && alias k=kubectl
test -x /usr/local/bin/kubectl && complete -o default -F __start_kubectl k
test -x /usr/local/bin/helm && source <(helm completion bash)
test -x /usr/local/bin/kubectx && alias kx=kubectx
EOF

cat <<'EOF'>> ~/.zshrc
test -x /usr/local/bin/kubectl && source <(kubectl completion zsh)
test -x /usr/local/bin/kubectl && alias k=kubectl
test -x /usr/local/bin/kubectl && compdef k=kubectl
test -x /usr/local/bin/helm && source <(helm completion zsh)
test -x /usr/local/bin/kubectx && alias kx=kubectx
EOF

KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
sudo curl -fsSL https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64 -o /usr/local/bin/kind
sudo chmod +x /usr/local/bin/kind

curl -L# https://github.com/WiltonCarvalho/kubernetes/raw/main/kind-metal-lb-nginx-ingress/kind-config.yaml -o ~/kind-config.yaml

kind delete cluster
docker network rm kind
docker network create kind --subnet 172.31.0.0/16

K8S_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
kind create cluster --image kindest/node:$K8S_VERSION --config ~/kind-config.yaml

kubectl version
kubectl get node
helm version

METALLB_VERSION=$(curl -s https://api.github.com/repos/metallb/metallb/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/$METALLB_VERSION/config/manifests/metallb-native.yaml
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
