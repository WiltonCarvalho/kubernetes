resource "helm_release" "metrics-server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server"
  chart            = "metrics-server"
  namespace        = "kube-system"
  create_namespace = false
  version          = "3.11.0"
  values           = [file("./${path.module}/values.yaml")]
}
