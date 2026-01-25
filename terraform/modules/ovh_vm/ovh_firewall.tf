data "ovh_vps" "ovh_cloud_homelab_gateway_01_dt" {
  service_name = "vps-0af37821.vps.ovh.ca"
}

resource "ovh_ip_firewall" "ovh_cloud_vps_firewall" {
  ip             = "51.161.34.166"
  ip_on_firewall = "51.161.34.166"
  enabled        = true
}

resource "ovh_ip_firewall_rule" "ovh_cloud_vps_firewall_rule_tcp" {
  ip             = ovh_ip_firewall.ovh_cloud_vps_firewall.ip
  ip_on_firewall = ovh_ip_firewall.ovh_cloud_vps_firewall.ip_on_firewall
  sequence       = 0
  action         = "permit"
  protocol       = "tcp"
  tcp_option     = "established"
}

resource "ovh_ip_firewall_rule" "ovh_cloud_vps_firewall_rule_ssh" {
  ip               = ovh_ip_firewall.ovh_cloud_vps_firewall.ip
  ip_on_firewall   = ovh_ip_firewall.ovh_cloud_vps_firewall.ip_on_firewall
  sequence         = 1
  action           = "permit"
  protocol         = "tcp"
  destination_port = 32222
}

resource "ovh_ip_firewall_rule" "ovh_cloud_vps_firewall_rule_http" {
  ip               = ovh_ip_firewall.ovh_cloud_vps_firewall.ip
  ip_on_firewall   = ovh_ip_firewall.ovh_cloud_vps_firewall.ip_on_firewall
  sequence         = 2
  action           = "permit"
  protocol         = "tcp"
  destination_port = 80
}

resource "ovh_ip_firewall_rule" "ovh_cloud_vps_firewall_rule_https" {
  ip               = ovh_ip_firewall.ovh_cloud_vps_firewall.ip
  ip_on_firewall   = ovh_ip_firewall.ovh_cloud_vps_firewall.ip_on_firewall
  sequence         = 3
  action           = "permit"
  protocol         = "tcp"
  destination_port = 443
}

resource "ovh_ip_firewall_rule" "ovh_cloud_vps_firewall_rule_wireguard" {
  ip               = ovh_ip_firewall.ovh_cloud_vps_firewall.ip
  ip_on_firewall   = ovh_ip_firewall.ovh_cloud_vps_firewall.ip_on_firewall
  sequence         = 4
  action           = "permit"
  protocol         = "udp"
  destination_port = 51820
}

resource "ovh_ip_firewall_rule" "ovh_cloud_vps_firewall_rule_wireguard_client" {
  ip               = ovh_ip_firewall.ovh_cloud_vps_firewall.ip
  ip_on_firewall   = ovh_ip_firewall.ovh_cloud_vps_firewall.ip_on_firewall
  sequence         = 6
  action           = "permit"
  protocol         = "udp"
  destination_port = 21820
}

resource "ovh_ip_firewall_rule" "ovh_cloud_vps_firewall_rule_dns" {
  ip             = ovh_ip_firewall.ovh_cloud_vps_firewall.ip
  ip_on_firewall = ovh_ip_firewall.ovh_cloud_vps_firewall.ip_on_firewall
  sequence       = 5
  action         = "permit"
  protocol       = "udp"
  source_port    = 53
}

resource "ovh_ip_firewall_rule" "ovh_cloud_vps_firewall_rule_deny" {
  ip             = ovh_ip_firewall.ovh_cloud_vps_firewall.ip
  ip_on_firewall = ovh_ip_firewall.ovh_cloud_vps_firewall.ip_on_firewall
  sequence       = 19
  action         = "deny"
  protocol       = "ipv4"
}
