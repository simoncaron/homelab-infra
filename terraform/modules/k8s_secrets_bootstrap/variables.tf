variable "secrets" {
  description = "Map of secrets to create"
  type = map(object({
    namespace = object({
      name   = string
      create = optional(bool, false)
      labels = optional(map(string), {})
    })
    secret = object({
      name   = string
      type   = optional(string, "Opaque")
      labels = optional(map(string), {})
      data   = map(string)
    })
  }))
}