variable "pve_cluster_nodes" {
  type    = set(string)
  default = []
}

variable "pools" {
  type = list(object({
    pool_id = string
    comment = string
  }))
  default = []
}

variable "dns_config" {
  type = object({
    domain  = string
    servers = list(string)
  })
  default = {
    domain  = ""
    servers = []
  }
}

variable "users" {
  type = map(object({
    name        = string
    realm       = string
    description = optional(string)

    token = object({
      name        = string
      description = optional(string)
    })

    roles = list(object({
      name       = string
      privileges = list(string)
    }))
  }))
  default = {}
}