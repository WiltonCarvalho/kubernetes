# KinD Cluster
curl -L# https://github.com/WiltonCarvalho/kubernetes/raw/main/kind-metal-lb-nginx-ingress/kind-config.yaml -o ~/kind-config.yaml

docker network create kind --subnet 172.31.0.0/16
kind create cluster --image kindest/node:v1.30.8 --config ~/kind-config.yaml

# Deploy Cluster Statefulset
kubectl create ns valkey

kubectl apply -f redis/valkey-cluster.yaml

kubectl -n valkey get pod

# Join Cluster Nodes
kubectl exec -it -n valkey valkey-masters-0 -c role-checker -- ash

valkey-cli --cluster create --cluster-yes --cluster-replicas 0 \
  valkey-masters-0.valkey-masters.valkey.svc.cluster.local:6379 \
  valkey-masters-1.valkey-masters.valkey.svc.cluster.local:6379 \
  valkey-masters-2.valkey-masters.valkey.svc.cluster.local:6379

valkey-cli --cluster add-node \
  valkey-replicas-0.valkey-replicas.valkey.svc.cluster.local:6379 \
  valkey-masters-0.valkey-masters.valkey.svc.cluster.local:6379 --cluster-slave

valkey-cli --cluster add-node \
  valkey-replicas-1.valkey-replicas.valkey.svc.cluster.local:6379 \
  valkey-masters-1.valkey-masters.valkey.svc.cluster.local:6379 --cluster-slave

valkey-cli --cluster add-node \
  valkey-replicas-2.valkey-replicas.valkey.svc.cluster.local:6379 \
  valkey-masters-2.valkey-masters.valkey.svc.cluster.local:6379 --cluster-slave

exit

# Verify Cluster Roles
for x in $(seq 0 2); do echo "valkey-masters-$x"; kubectl exec -n valkey valkey-masters-$x  -- ash -c 'valkey-cli role; echo'; done
for x in $(seq 0 2); do echo "valkey-replicas-$x"; kubectl exec -n valkey valkey-replicas-$x -- ash -c 'valkey-cli role; echo'; done

# Verify Replication
kubectl -n valkey logs valkey-masters-0
kubectl -n valkey logs valkey-replicas-0

# Test Redis Write
kubectl exec -it -n valkey valkey-masters-0 -c role-checker -- ash
valkey-cli cluster slots
valkey-cli -c set foo bar
valkey-cli -c get foo
for x in $(seq 0 2); do valkey-cli -c -h valkey-masters-$x.valkey-masters.valkey.svc.cluster.local keys "*"; done

exit

# Locust load + failover test
kubectl apply -f redis/valkey-client.yaml
kubectl -n valkey port-forward valkey-client-0 8089:8089

# Start Test
google-chrome --incognito http://localhost:8089

# Delete a master node 0
kubectl -n valkey delete statefulset valkey-masters --cascade=orphan

kubectl -n valkey delete pod valkey-masters-0

# Watch the relica 0 taking the master role
kubectl -n valkey get pods

kubectl -n valkey logs valkey-replicas-0

# Re-apply to recreate the master node 0
kubectl apply -f redis/valkey-cluster.yaml

# Watch the master node 0 re-taking the master role
kubectl -n valkey logs valkey-masters-0
kubectl -n valkey logs valkey-masters-0 -c role-checker

# Delete
kubectl delete -f redis/valkey-client.yaml
kubectl delete -f redis/valkey-cluster.yaml
kubectl -n valkey delete pvc data-valkey-masters-0   data-valkey-masters-2   data-valkey-replicas-1 data-valkey-masters-1   data-valkey-replicas-0  data-valkey-replicas-2

kubectl delete ns valkey

kind delete cluster