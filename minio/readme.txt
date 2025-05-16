helm repo add minio-operator https://operator.min.io
helm search repo minio-operator
helm install \
  --namespace minio-operator \
  --create-namespace \
  operator minio-operator/operator --version 7.0.1
kubectl get all -n minio-operator

helm repo add minio-operator https://operator.min.io
helm search repo minio-operator
curl -fsSL -o minio/values.yaml https://raw.githubusercontent.com/minio/operator/master/helm/tenant/values.yaml

helm install \
--namespace myminio \
--create-namespace \
--values minio/values.yaml \
myminio minio-operator/tenant --version 7.0.1