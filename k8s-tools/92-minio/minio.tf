resource "helm_release" "minio-operator" {
  name = "minio-operator"
  repository       = "https://operator.min.io"
  chart            = "minio-operator"
  version          = "4.3.7"
  namespace        = "minio-operator"
  create_namespace = true
  values           = [file("./${path.module}/operator-values.yaml")]
  set {
    name  = "console.image.repository"
    value = "quay.io/minio/console"
  }
  set {
    name  = "operator.image.repository"
    value = "quay.io/minio/operator"
  }
}

resource "helm_release" "minio-tenant" {
  name = "minio"
  repository       = "https://operator.min.io"
  chart            = "tenant"
  version          = "7.0.1"
  namespace        = "default"
  create_namespace = true
  values           = [file("./${path.module}/tenant-values.yaml")]
  depends_on = [
    helm_release.minio-operator
  ]
}