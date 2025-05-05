resource "kubernetes_namespace" "namespaces" {
  for_each = {
    for key, secret in var.secrets : key => secret
    if secret.namespace.create
  }

  metadata {
    name   = each.value.namespace.name
    labels = each.value.namespace.labels
  }
}

resource "kubernetes_secret" "secrets" {
  for_each = var.secrets

  depends_on = [kubernetes_namespace.namespaces]

  metadata {
    name      = each.value.secret.name
    namespace = each.value.namespace.name
    labels    = each.value.secret.labels
  }

  data = each.value.secret.data
  type = each.value.secret.type
}