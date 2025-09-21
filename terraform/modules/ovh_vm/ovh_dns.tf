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

resource "adguard_rewrite" "gateway01_adguardhome_dns_record" {
  answer = "51.161.34.166"
  domain = "gateway01.simn.io"
}

resource "adguard_rewrite" "pg_adguardhome_dns_record" {
  answer = "gateway01.simn.io"
  domain = "pg.simn.io"
}

