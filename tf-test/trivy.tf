resource "helm_release" "trivy_operator" {
  name             = "trivy-operator"
  repository       = "https://aquasecurity.github.io/helm-charts/"
  chart            = "trivy-operator"
  namespace        = "trivy-system"
  create_namespace = true

  version = "0.22.0"

  set = [{
    name  = "trivy.ignoreUnfixed"
    value = "true"
    },
    {
      name  = "operator.scanJobCompressLogs"
      value = "true"
    },
    {
      name  = "operator.replicas"
      value = "1"
    },
    {
      name  = "operator.scanJobTimeout"
      value = "5m"
    },
    {
      name  = "operator.scanJobReportsStdout"
      value = "true"
    }
  ]

  depends_on = [google_container_cluster.primary]
}
