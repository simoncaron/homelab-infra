resource "kubernetes_namespace" "namespace" {
  count = var.namespace.create == true ? 1 : 0
  metadata {
    name = var.namespace.name
  }
}

resource "kubernetes_secret" "sealed-secrets-key" {
  type = "kubernetes.io/tls"

  metadata {
    name      = "sealed-secrets-bootstrap-key"
    namespace = var.namespace.name
    labels = {
      "sealedsecrets.bitnami.com/sealed-secrets-key" = "active"
    }
  }

  data = {
    "tls.crt" = var.cert.cert
    "tls.key" = var.cert.key
  }
}
