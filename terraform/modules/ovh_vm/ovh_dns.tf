# Cloudflare Provider DNS Records
data "cloudflare_zone" "simn_io" {
  filter = {
    name = "simn.io"
  }
}

resource "cloudflare_dns_record" "gateway01_a_record" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "gateway01.simn.io"
  content = "51.161.34.166"
  type    = "A"
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "pangolin_a_record" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "pg.simn.io"
  content = "gateway01.simn.io"
  type    = "CNAME"
  proxied = false
  ttl     = 3600
}

resource "powerdns_record" "gateway01_powerdns_dns_record" {
  zone    = "simn.io."
  name    = "gateway01.simn.io."
  type    = "A"
  ttl     = 300
  records = ["51.161.34.166"]
}

resource "powerdns_record" "pg_powerdns_dns_record" {
  zone    = "simn.io."
  name    = "pg.simn.io."
  type    = "CNAME"
  ttl     = 300
  records = ["gateway01.simn.io."]
}
