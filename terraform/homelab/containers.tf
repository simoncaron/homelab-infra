resource "proxmox_virtual_environment_file" "vpn_config_hook_script" {
  content_type = "snippets"
  datastore_id = "cephfs"
  node_name    = "pvenuc01" # Not really important since cephfs is shared

  file_mode = "0700"

  source_raw {
    data      = <<-EOF
      #!/usr/bin/perl
      use strict;
      use warnings;

      my $vmid = shift;
      my $phase = shift;

      if ($phase eq 'pre-start') {

          my $file = "/etc/pve/lxc/$${vmid}.conf";

          my @lines_to_add = (
              'lxc.cgroup2.devices.allow: c 10:200 rwm',
              'lxc.mount.entry: /dev/net dev/net none bind,create=dir',
          );

          open(my $fh, '<', $file) or die "Failed to open file '$file' : $!";
          my @file_contents = <$fh>;
          close($fh);

          @file_contents = grep {
              !/^lxc\.mount\.entry/ && !/^lxc\.cgroup2\.devices\.allow/
          } @file_contents;

          foreach my $line (@lines_to_add) {
              unless (grep { $_ =~ /^\Q$line\E$/ } @file_contents) {
                  push @file_contents, "$line\n";
              }
          }

          open(my $fh_out, '>', $file) or die "Failed to open file '$file' in write mode : $!";
          print $fh_out @file_contents;
          close($fh_out);
      }
      EOF
    file_name = "vpn-config-hook-script.pl"
  }
}

resource "proxmox_virtual_environment_download_file" "debian_12_container_template" {
  content_type = "vztmpl"
  datastore_id = "cephfs"
  node_name    = "pvenuc01" # Not really important since cephfs is shared
  url          = "http://mirror.overthewire.com.au/proxmox/images/system/debian-12-standard_12.0-1_amd64.tar.zst"
  overwrite    = false
}

resource "proxmox_virtual_environment_download_file" "debian_12_2_container_template" {
  content_type = "vztmpl"
  datastore_id = "cephfs"
  node_name    = "pvenuc01" # Not really important since cephfs is shared
  url          = "http://download.proxmox.com/images/system/debian-12-standard_12.2-1_amd64.tar.zst"
  overwrite    = false
}

module "lxc_dns02" {
  source = "../modules/proxmox_lxc"

  vm_id     = 114
  hostname  = "dns02"
  node_name = "pvenuc01"

  description = <<EOT
# dns02.simn.io
AdGuard Home DNS Server
EOT

  root_password   = data.bitwarden_item_login.default_root_password.password
  ssh_public_keys = [data.bitwarden_item_login.default_ssh_public_key.password]

  features = {
    keyctl  = true
    nesting = true
  }

  dns_config = {
    domain  = "simn.io"
    servers = ["1.1.1.1", "1.0.0.1"]
  }

  network_interfaces = [
    {
      name     = "eth0"
      bridge   = "vmbr0"
      firewall = true
      ipv4     = { address = "192.168.1.114/24", gateway = "192.168.1.1" }
      ipv6     = { address = "auto" }
    },
    {
      name   = "eth1"
      bridge = "vmbr1"
      ipv4   = { address = "10.10.10.114/24", gateway = "10.10.10.1" }
      ipv6   = { address = "auto" }
    }
  ]

  template_file_id    = proxmox_virtual_environment_download_file.debian_12_container_template.id
  hook_script_file_id = proxmox_virtual_environment_file.vpn_config_hook_script.id
  tags                = ["debian", "dns-lxc", "tailscale"]

  cpu_cores        = 2
  memory_dedicated = 512
  disk_size        = 8

  # adguard_rewrite_rules = [
  #   { domain = "dns02.simn.io", answer = "192.168.1.114" },
  # ]

  firewall_rules_enabled = true
  firewall_rules = [
    { type = "in", action = "ACCEPT", iface = "net0", macro = "SSH", comment = "Allow SSH for dns02" },
    { type = "in", action = "ACCEPT", iface = "net0", dest = "192.168.1.114", dport = "53", proto = "udp", comment = "AdGuard DNS UDP for dns02" },
    { type = "in", action = "ACCEPT", iface = "net0", dest = "192.168.1.114", dport = "80,443", proto = "tcp", comment = "AdGuard Web UI TCP for dns02" }
  ]
}

module "lxc_newt01" {
  source = "../modules/proxmox_lxc"

  vm_id     = 118
  hostname  = "newt01"
  node_name = "pvenuc02"

  description = <<EOT
# newt01.simn.io
New Tunnel Local Tunnel
EOT

  root_password   = data.bitwarden_item_login.default_root_password.password
  ssh_public_keys = [data.bitwarden_item_login.default_ssh_public_key.password]

  features = {
    keyctl  = true
    nesting = true
  }

  dns_config = {
    domain  = "simn.io"
    servers = ["1.1.1.1", "1.0.0.1"]
  }

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vmbr1"
      ipv4   = { address = "10.10.10.118/24", gateway = "10.10.10.1" }
      ipv6   = { address = "auto" }
    }
  ]

  template_file_id    = proxmox_virtual_environment_download_file.debian_12_container_template.id
  hook_script_file_id = proxmox_virtual_environment_file.vpn_config_hook_script.id
  tags                = ["debian", "newt", "pangolin"]

  cpu_cores        = 2
  memory_dedicated = 512
  disk_size        = 8

  # adguard_rewrite_rules = [
  #   { domain = "newt01.simn.io", answer = "10.10.10.118" },
  # ]
}

module "lxc_jellyfin01" {
  source = "../modules/proxmox_lxc"

  vm_id     = 125
  hostname  = "jellyfin01"
  node_name = "pvenuc01"

  root_password   = data.bitwarden_item_login.default_root_password.password
  ssh_public_keys = [data.bitwarden_item_login.default_ssh_public_key.password]

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vmbr0"
      ipv4   = { address = "192.168.1.125/24", gateway = "192.168.1.1" }
      ipv6   = { address = "auto" }
    }
  ]

  template_file_id = proxmox_virtual_environment_download_file.debian_12_2_container_template.id
  tags             = ["debian", "jellyfin", "gpu"]

  cpu_cores        = 2
  memory_dedicated = 4096
  disk_size        = 128

  mount_points = [
    { path = "/media", volume = "/mnt/pve/remote-cifs-truenas01", backup = false }
  ]

  # adguard_rewrite_rules = [
  #   { domain = "jellyfin01.simn.io", answer = "192.168.1.125" },
  #   { domain = "jellyfin.simn.io", answer = "192.168.1.113" }
  # ]
}

module "lxc_plex01" {
  source = "../modules/proxmox_lxc"

  vm_id     = 124
  hostname  = "plex01"
  node_name = "pvenuc02"

  root_password   = data.bitwarden_item_login.default_root_password.password
  ssh_public_keys = [data.bitwarden_item_login.default_ssh_public_key.password]

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vmbr0"
      ipv4   = { address = "192.168.1.124/24", gateway = "192.168.1.1" }
      ipv6   = { address = "auto" }
    },
    {
      name   = "eth1"
      bridge = "vmbr1"
      ipv4   = { address = "10.10.10.124/24", gateway = "10.10.10.1" }
      ipv6   = { address = "auto" }
    }
  ]

  template_file_id = proxmox_virtual_environment_download_file.debian_12_2_container_template.id
  tags             = ["debian", "plex", "gpu"]

  cpu_cores        = 2
  memory_dedicated = 4096
  disk_size        = 128

  mount_points = [
    { path = "/data", volume = "/mnt/pve/remote-cifs-truenas01", backup = false }
  ]

  # adguard_rewrite_rules = [
  #   { domain = "plex01.simn.io", answer = "192.168.1.124" },
  #   { domain = "plex.simn.io", answer = "192.168.1.113" }
  # ]
}

module "lxc_tdarr01" {
  source = "../modules/proxmox_lxc"

  vm_id     = 129
  hostname  = "tdarr01"
  node_name = "pvenuc03"

  root_password   = data.bitwarden_item_login.default_root_password.password
  ssh_public_keys = [data.bitwarden_item_login.default_ssh_public_key.password]

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vmbr1"
      ipv4   = { address = "10.10.10.129/24", gateway = "10.10.10.1" }
      ipv6   = { address = "auto" }
    }
  ]

  template_file_id = proxmox_virtual_environment_download_file.debian_12_2_container_template.id
  tags             = ["debian", "tdarr", "gpu"]

  cpu_cores        = 4
  memory_dedicated = 4096
  disk_size        = 128

  mount_points = [
    { path = "/mnt/media", volume = "/mnt/pve/remote-cifs-truenas01", backup = false }
  ]

  # adguard_rewrite_rules = [
  #   { domain = "tdarr01.simn.io", answer = "10.10.10.129" },
  #   { domain = "tdarr.simn.io", answer = "192.168.1.113" }
  # ]
}

module "lxc_forgejo01" {
  source = "../modules/proxmox_lxc"

  vm_id     = 127
  hostname  = "forgejo01"
  node_name = "pvenuc03"

  root_password   = data.bitwarden_item_login.default_root_password.password
  ssh_public_keys = [data.bitwarden_item_login.default_ssh_public_key.password]

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vmbr1"
      ipv4   = { address = "10.10.10.127/24", gateway = "10.10.10.1" }
      ipv6   = { address = "auto" }
    }
  ]

  template_file_id = proxmox_virtual_environment_download_file.debian_12_2_container_template.id
  tags             = ["debian", "git", "forgejo"]

  cpu_cores        = 4
  memory_dedicated = 4096
  disk_size        = 128

  # adguard_rewrite_rules = [
  #   { domain = "forgejo01.simn.io", answer = "10.10.10.127" },
  #   { domain = "git.simn.io", answer = "192.168.1.113" }
  # ]
}

module "lxc_proxy01" {
  source = "../modules/proxmox_lxc"

  vm_id     = 113
  hostname  = "proxy01"
  node_name = "pvenuc01"

  description = <<EOT
# proxy01.simn.io
Private traefik routing proxy for vmbr1
EOT

  root_password   = data.bitwarden_item_login.default_root_password.password
  ssh_public_keys = [data.bitwarden_item_login.default_ssh_public_key.password]

  features = {
    nesting = true
    keyctl  = true
  }

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vmbr0"
      ipv4   = { address = "192.168.1.113/24", gateway = "192.168.1.1" }
      ipv6   = { address = "auto" }
    },
    {
      name   = "eth1"
      bridge = "vmbr1"
      ipv4   = { address = "10.10.10.113/24", gateway = "10.10.10.1" }
      ipv6   = { address = "auto" }
    }
  ]

  template_file_id    = proxmox_virtual_environment_download_file.debian_12_container_template.id
  hook_script_file_id = proxmox_virtual_environment_file.vpn_config_hook_script.id
  tags                = ["debian", "proxy", "tailscale"]

  # adguard_rewrite_rules = [
  #   { domain = "proxy01.simn.io", answer = "192.168.1.113" },
  # ]
}
