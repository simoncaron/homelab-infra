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
    # Configure as an exit node
    "0.0.0.0/0",
    "::/0"
  ]
}

resource "tailscale_device_subnet_routes" "dns02_subnet_routes" {
  device_id = data.tailscale_device.dns02_tailscale_device.id
  routes = [
    "192.168.1.0/24",
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
  acl = <<EOF
    // Example/default ACLs for unrestricted connections.
    {
      // Declare static groups of users. Use autogroups for all users or users with a specific role.
      // "groups": {
      //   "group:example": ["alice@example.com", "bob@example.com"],
      // },

      // Define the tags which can be applied to devices and by which users.
      // "tagOwners": {
      //   "tag:example": ["autogroup:admin"],
      // },

      // Define grants that govern access for users, groups, autogroups, tags,
      // Tailscale IP addresses, and subnet ranges.
      "grants": [
        // Allow all connections.
        // Comment this section out if you want to define specific restrictions.
        {
          "src": ["*"],
          "dst": ["*"],
          "ip":  ["*"],
        },

        // Allow users in "group:example" to access "tag:example", but only from
        // devices that are running macOS and have enabled Tailscale client auto-updating.
        // {"src": ["group:example"], "dst": ["tag:example"], "ip": ["*"], "srcPosture":["posture:autoUpdateMac"]},
      ],

      // Define postures that will be applied to all rules without any specific
      // srcPosture definition.
      // "defaultSrcPosture": [
      //      "posture:anyMac",
      // ],

      // Define device posture rules requiring devices to meet
      // certain criteria to access parts of your system.
      // "postures": {
      //      // Require devices running macOS, a stable Tailscale
      //      // version and auto update enabled for Tailscale.
      //  "posture:autoUpdateMac": [
      //      "node:os == 'macos'",
      //      "node:tsReleaseTrack == 'stable'",
      //      "node:tsAutoUpdate",
      //  ],
      //      // Require devices running macOS and a stable
      //      // Tailscale version.
      //  "posture:anyMac": [
      //      "node:os == 'macos'",
      //      "node:tsReleaseTrack == 'stable'",
      //  ],
      // },

      // Define users and devices that can use Tailscale SSH.
      "ssh": [
        // Allow all users to SSH into their own devices in check mode.
        // Comment this section out if you want to define specific restrictions.
        {
          "action": "check",
          "src":    ["autogroup:member"],
          "dst":    ["autogroup:self"],
          "users":  ["autogroup:nonroot", "root"],
        },
      ],

      "tagOwners": {
        "tag:dns":   ["simon.caron.8@gmail.com"],
        "tag:proxy": ["simon.caron.8@gmail.com"],
      },

      // Test access rules every time they're saved.
      // "tests": [
      //   {
      //       "src": "alice@example.com",
      //       "accept": ["tag:example"],
      //       "deny": ["100.101.102.103:443"],
      //   },
      // ],
    }
  EOF
}
