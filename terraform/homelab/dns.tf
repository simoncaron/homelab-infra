data "cloudflare_zone" "crappy-mail_com" {
  filter = {
    name = "crappy-mail.com"
  }
}

data "cloudflare_zone" "simn_io" {
  filter = {
    name = "simn.io"
  }
}

data "cloudflare_zone" "simoncaron_com" {
  filter = {
    name = "simoncaron.com"
  }
}

resource "cloudflare_dns_record" "simn_protonmail_dkim1" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "protonmail._domainkey.simn.io"
  content = "protonmail.domainkey.d7pc7fg7leraeczopwfrfxyvqz64easa7lyrtu33yqpwg23e36xoa.domains.proton.ch"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "simn_protonmail_dkim2" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "protonmail2._domainkey.simn.io"
  content = "protonmail2.domainkey.d7pc7fg7leraeczopwfrfxyvqz64easa7lyrtu33yqpwg23e36xoa.domains.proton.ch"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "simn_protonmail_dkim3" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "protonmail3._domainkey.simn.io"
  content = "protonmail3.domainkey.d7pc7fg7leraeczopwfrfxyvqz64easa7lyrtu33yqpwg23e36xoa.domains.proton.ch"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "simn_mx1" {
  zone_id  = data.cloudflare_zone.simn_io.zone_id
  name     = "simn.io"
  content  = "mail.protonmail.ch"
  type     = "MX"
  proxied  = false
  priority = 10
  ttl      = 1
}

resource "cloudflare_dns_record" "simn_mx2" {
  zone_id  = data.cloudflare_zone.simn_io.zone_id
  name     = "simn.io"
  content  = "mailsec.protonmail.ch"
  type     = "MX"
  proxied  = false
  priority = 20
  ttl      = 1
}

resource "cloudflare_dns_record" "simn_txt1" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "_dmarc.simn.io"
  content = "v=DMARC1; p=none; rua=mailto:admin@simn.io"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "simn_txt2" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "simn.io"
  content = "protonmail-verification=5a58c463c60c57bbe05bbee0de65658ab623c4bc"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "simn_txt3" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "simn.io"
  content = "v=spf1 include:_spf.protonmail.ch mx ~all"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "letsencrypt_CAA1" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "simn.io"
  data = {
    flags = "0"
    tag   = "issuewild"
    value = "letsencrypt.org"
  }
  type    = "CAA"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "letsencrypt_CAA3" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "simn.io"
  data = {
    flags = "0"
    tag   = "iodef"
    value = "mailto:admin@simoncaron.com"
  }
  type    = "CAA"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "letsencrypt_CAA2" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "simn.io"
  data = {
    flags = "0"
    tag   = "issue"
    value = "letsencrypt.org"
  }
  type    = "CAA"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "smtp2go_CNAME1" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "em1384314.simn.io"
  content = "return.smtp2go.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "smtp2go_CNAME2" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "s1384314._domainkey.simn.io"
  content = "dkim.smtp2go.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "smtp2go_CNAME3" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "link.simn.io"
  content = "track.smtp2go.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "plex_ts_a_record" {
  zone_id = data.cloudflare_zone.simn_io.zone_id
  name    = "pms.simn.io"
  content = "gateway01.simn.io"
  type    = "CNAME"
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "crappy-mail_dkim1" {
  zone_id = data.cloudflare_zone.crappy-mail_com.zone_id
  name    = "dkim._domainkey.crappy-mail.com"
  content = "dkim._domainkey.simplelogin.co"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "crappy-mail_dkim2" {
  zone_id = data.cloudflare_zone.crappy-mail_com.zone_id
  name    = "dkim02._domainkey.crappy-mail.com"
  content = "dkim02._domainkey.simplelogin.co"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "crappy-mail_dkim3" {
  zone_id = data.cloudflare_zone.crappy-mail_com.zone_id
  name    = "dkim03._domainkey.crappy-mail.com"
  content = "dkim03._domainkey.simplelogin.co"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "crappy-mail_com" {
  zone_id = data.cloudflare_zone.crappy-mail_com.zone_id
  name    = "crappy-mail.com"
  content = "parkingpage.namecheap.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "crappy-mail_mx1" {
  zone_id  = data.cloudflare_zone.crappy-mail_com.zone_id
  name     = "crappy-mail.com"
  content  = "mx1.simplelogin.co"
  type     = "MX"
  proxied  = false
  priority = 10
  ttl      = 1
}

resource "cloudflare_dns_record" "crappy-mail_mx2" {
  zone_id  = data.cloudflare_zone.crappy-mail_com.zone_id
  name     = "crappy-mail.com"
  content  = "mx2.simplelogin.co"
  type     = "MX"
  proxied  = false
  priority = 20
  ttl      = 1
}

resource "cloudflare_dns_record" "crappy-mail_txt1" {
  zone_id = data.cloudflare_zone.crappy-mail_com.zone_id
  name    = "_dmarc.crappy-mail.com"
  content = "v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "crappy-mail_txt2" {
  zone_id = data.cloudflare_zone.crappy-mail_com.zone_id
  name    = "crappy-mail.com"
  content = "sl-verification=rykphiqtcyjpeazxoqekxilfwitnvo"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "crappy-mail_txt3" {
  zone_id = data.cloudflare_zone.crappy-mail_com.zone_id
  name    = "crappy-mail.com"
  content = "v=spf1 include:simplelogin.co ~all"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "protonmail_dkim1" {
  zone_id = data.cloudflare_zone.simoncaron_com.zone_id
  name    = "protonmail._domainkey.simoncaron.com"
  content = "protonmail.domainkey.d2ji4vuyasehauhcs7y7pj4m5hjhazchfno5zpukpapwfamjz5rkq.domains.proton.ch"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "protonmail_dkim2" {
  zone_id = data.cloudflare_zone.simoncaron_com.zone_id
  name    = "protonmail2._domainkey.simoncaron.com"
  content = "protonmail2.domainkey.d2ji4vuyasehauhcs7y7pj4m5hjhazchfno5zpukpapwfamjz5rkq.domains.proton.ch"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "protonmail_dkim3" {
  zone_id = data.cloudflare_zone.simoncaron_com.zone_id
  name    = "protonmail3._domainkey.simoncaron.com"
  content = "protonmail3.domainkey.d2ji4vuyasehauhcs7y7pj4m5hjhazchfno5zpukpapwfamjz5rkq.domains.proton.ch"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "simoncaron_com" {
  zone_id = data.cloudflare_zone.simoncaron_com.zone_id
  name    = "simoncaron.com"
  content = "parkingpage.namecheap.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "simoncaron_mx1" {
  zone_id  = data.cloudflare_zone.simoncaron_com.zone_id
  name     = "simoncaron.com"
  content  = "mail.protonmail.ch"
  type     = "MX"
  proxied  = false
  priority = 10
  ttl      = 1
}

resource "cloudflare_dns_record" "simoncaron_mx2" {
  zone_id  = data.cloudflare_zone.simoncaron_com.zone_id
  name     = "simoncaron.com"
  content  = "mailsec.protonmail.ch"
  type     = "MX"
  proxied  = false
  priority = 20
  ttl      = 1
}

resource "cloudflare_dns_record" "simoncaron_txt1" {
  zone_id = data.cloudflare_zone.simoncaron_com.zone_id
  name    = "_dmarc.simoncaron.com"
  content = "v=DMARC1; p=none; rua=mailto:admin@simoncaron.com"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "simoncaron_txt2" {
  zone_id = data.cloudflare_zone.simoncaron_com.zone_id
  name    = "simoncaron.com"
  content = "protonmail-verification=c07d1fc9951d302aaf45ae37e473d1a1229c731f"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "simoncaron_txt3" {
  zone_id = data.cloudflare_zone.simoncaron_com.zone_id
  name    = "simoncaron.com"
  content = "v=spf1 include:_spf.protonmail.ch mx ~all"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "powerdns_zone" "simn_io" {
  name         = "simn.io."
  kind         = "Master"
  nameservers  = ["ns1.simn.io.", "ns2.simn.io."]
  soa_edit_api = "DEFAULT"
}

resource "powerdns_zone" "priv_simn_io" {
  name         = "priv.simn.io."
  kind         = "Master"
  nameservers  = ["ns1.simn.io.", "ns2.simn.io."]
  soa_edit_api = "DEFAULT"
}

resource "powerdns_zone" "pub_simn_io" {
  name         = "pub.simn.io."
  kind         = "Master"
  nameservers  = ["ns1.simn.io.", "ns2.simn.io."]
  soa_edit_api = "DEFAULT"
}

resource "powerdns_zone" "in_addr_arpa_10" {
  name         = "10.in-addr.arpa."
  kind         = "Master"
  nameservers  = ["ns1.simn.io.", "ns2.simn.io."]
  soa_edit_api = "DEFAULT"
}

resource "powerdns_zone" "simn_io_secondary" {
  name     = "simn.io."
  kind     = "Slave"
  masters  = ["192.168.1.10:5353"]
  provider = powerdns.pdns_secondary
}

resource "powerdns_zone" "priv_simn_io_secondary" {
  name     = "priv.simn.io."
  kind     = "Slave"
  masters  = ["192.168.1.10:5353"]
  provider = powerdns.pdns_secondary
}

resource "powerdns_zone" "pub_simn_io_secondary" {
  name     = "pub.simn.io."
  kind     = "Slave"
  masters  = ["192.168.1.10:5353"]
  provider = powerdns.pdns_secondary
}

resource "powerdns_zone" "in_addr_arpa_10_secondary" {
  name     = "10.in-addr.arpa."
  kind     = "Slave"
  masters  = ["192.168.1.10:5353"]
  provider = powerdns.pdns_secondary
}

resource "powerdns_record" "ns1" {
  zone    = powerdns_zone.simn_io.id
  name    = "ns1.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.10"]
}

resource "powerdns_record" "ns2" {
  zone    = powerdns_zone.simn_io.id
  name    = "ns2.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.114"]
}

resource "powerdns_record" "pbs01_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "pbs01.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.100"]
}

resource "powerdns_record" "dns01_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "dns01.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.10"]
}

resource "powerdns_record" "s3_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "s3.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.100"]
}

resource "powerdns_record" "influx_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "influxdb.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.100"]
}

resource "powerdns_record" "truenas01_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "truenas01.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.100"]
}

resource "powerdns_record" "truenas01_ilo_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "ilo.truenas01.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.101"]
}

resource "powerdns_record" "pve01_ilo_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "ilo.pve01.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.200"]
}

resource "powerdns_record" "pms_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "pms.simn.io."
  type    = "CNAME"
  ttl     = 300
  records = ["gateway01.simn.io."]
}

resource "powerdns_record" "plex_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "plex.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.119"]
}

resource "powerdns_record" "homeassistant_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "homeassistant.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.133"]
}

resource "powerdns_record" "pve01_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "pve01.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.201"]
}

resource "powerdns_record" "default_simn_io_powerdns_dns_record" {
  zone    = powerdns_zone.simn_io.id
  name    = "*.simn.io."
  type    = "A"
  ttl     = 300
  records = ["192.168.1.113"]
}
