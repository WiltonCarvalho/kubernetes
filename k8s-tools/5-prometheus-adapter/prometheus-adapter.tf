resource "helm_release" "prometheus-adapter" {
  name             = "prometheus-adapter"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-adapter"
  version          = "4.9.0"
  namespace        = "monitoring"
  create_namespace = false
  values           = [file("./${path.module}/values.yaml")]
}
