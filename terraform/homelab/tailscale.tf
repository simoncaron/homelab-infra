data "tailscale_device" "dns01_tailscale_device" {
  name = "dns01.tail26f47.ts.net"
}

data "tailscale_device" "dns02_tailscale_device" {
  name = "dns02.tail26f47.ts.net"
}

data "tailscale_device" "proxy01_tailscale_device" {
  name = "proxy01.tail26f47.ts.net"
}

data "tailscale_device" "proxy02_tailscale_device" {
  name = "proxy02.tail26f47.ts.net"
}

resource "tailscale_dns_configuration" "tailscale_dns_configuration" {
  nameservers {
    address = "192.168.1.10"
  }
  nameservers {
    address = "192.168.1.114"
  }
  search_paths       = ["local", "simn.io"]
  override_local_dns = true
  magic_dns          = true
}

resource "tailscale_device_subnet_routes" "dns01_subnet_routes" {
  device_id = data.tailscale_device.dns01_tailscale_device.id
  routes = [
    "192.168.1.0/24",
    "192.168.10.0/24",
    "192.168.20.0/24",
    # Configure as an exit node
    "0.0.0.0/0",
    "::/0"
  ]
}

resource "tailscale_device_subnet_routes" "dns02_subnet_routes" {
  device_id = data.tailscale_device.dns02_tailscale_device.id
  routes = [
    "192.168.1.0/24",
    "192.168.10.0/24",
    "192.168.20.0/24",
    # Configure as an exit node
    "0.0.0.0/0",
    "::/0"
  ]
}

resource "tailscale_device_subnet_routes" "proxy01_subnet_routes" {
  device_id = data.tailscale_device.proxy01_tailscale_device.id
  routes = [
    "10.10.10.0/24",
  ]
}

resource "tailscale_device_subnet_routes" "proxy02_subnet_routes" {
  device_id = data.tailscale_device.proxy02_tailscale_device.id
  routes = [
    "10.10.20.0/24",
  ]
}

resource "tailscale_acl" "homelab_acls" {
  acl = jsonencode({
    "grants" : [
      {
        "src" : ["*"],
        "dst" : ["*"],
        "ip" : ["*"],
      },
    ],
    "ssh" : [
      {
        "action" : "check",
        "src" : ["autogroup:member"],
        "dst" : ["autogroup:self"],
        "users" : ["autogroup:nonroot", "root"],
      },
    ],
    "tagOwners" : {
      "tag:proxy" : [],
      "tag:dns" : [],
    },
  })
}
