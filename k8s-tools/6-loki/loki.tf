resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  namespace        = "loki"
  create_namespace = true
  version          = "5.39.0"
  values           = [file("./${path.module}/values.yaml")]
}
