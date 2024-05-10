kubectl -n kube-system create serviceaccount test-kubeconfig-sa

kubectl create clusterrolebinding test-kubeconfig-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:test-kubeconfig-sa

cat <<'EOF'> test-kubeconfig-sa-token.yaml
apiVersion: v1
kind: Secret
metadata:
  name: test-kubeconfig-sa-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: test-kubeconfig-sa
type: kubernetes.io/service-account-token
EOF

kubectl apply -f test-kubeconfig-sa-token.yaml

KUBE_CA=$(kubectl get cm kube-root-ca.crt -o jsonpath="{['data']['ca\.crt']}" | base64 -w 0)
KUBE_ENDPOINT=$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[].addresses[].ip}')
TOKEN=$(kubectl -n kube-system get secret test-kubeconfig-sa-token -o jsonpath='{.data.token}' | base64 --decode)

docker run -it --rm --net=host -e KUBE_CA=$KUBE_CA -e KUBE_ENDPOINT=$KUBE_ENDPOINT -e TOKEN=$TOKEN alpine ash
apk add kubectl

echo $KUBE_CA | base64 -d  > ca.crt

kubectl config set-cluster dev \
  --certificate-authority ca.crt --embed-certs=true \
  --server https://$KUBE_ENDPOINT:6443

kubectl config set-credentials test-kubeconfig-sa --token=$TOKEN

kubectl config set-context dev --cluster=dev --user=test-kubeconfig-sa

kubectl config use-context dev

kubectl get pods

kubectl run httpd --image httpd:alpine --port 80 --labels app=httpd

POD=$(kubectl get pod --selector app=httpd -o jsonpath='{.items[].metadata.name}')
kubectl port-forward $POD 8080:80

curl -s http://localhost:8080

kubectl delete pod httpd
