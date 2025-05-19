variable "namespace" {
  description = "Namespace where Sealed Secrets will be installed"
  type = object({
    name   = string
    create = optional(bool, false)
  })
  default = {
    name = "kube-system"
  }
}

variable "cert" {
  description = "Certificate for encryption/decryption"
  type = object({
    cert = string
    key  = string
  })
}