# terraform apply -target module.ingress --auto-approve
module "ingress" {
  source = "./2-ingress"
}
# terraform apply -target module.metrics-server --auto-approve
module "metrics-server" {
  source = "./3-metrics-server"
}
# terraform apply -target module.kube-prometheus-stack --auto-approve
module "kube-prometheus-stack" {
  source = "./4-kube-prometheus-stack"
  depends_on = [module.ingress]
}
# terraform apply -target module.prometheus-adapter --auto-approve
module "prometheus-adapter" {
  source = "./5-prometheus-adapter"
  depends_on = [module.kube-prometheus-stack]
}
# terraform apply -target module.loki --auto-approve
module "loki" {
  source = "./6-loki"
  depends_on = [module.kube-prometheus-stack]
}
# terraform apply -target module.promtail --auto-approve
module "promtail" {
  source = "./7-promtail"
  depends_on = [module.loki]
}
# terraform apply -target module.tempo --auto-approve
module "tempo" {
  source = "./8-tempo"
  depends_on = [module.kube-prometheus-stack]
}
# terraform apply -target module.otel --auto-approve
module "otel" {
  source = "./9-otel"
  depends_on = [module.tempo]
}
# terraform apply -target module.argocd --auto-approve
module "argocd" {
  source = "./91-argocd"
  depends_on = [module.kube-prometheus-stack]
}
