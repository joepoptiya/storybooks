provider "cloudflare" {
  #version    = "~> 2.0"
  email      = "joe.poptiya@gmail.com"
  api_key    = var.cloudflare_api_key
  account_id = var.cloudflare_account_id
}

# zone
data "cloudflare_zones" "cf_zones" {
  filter {
    name = var.domain
  }
}

# DNS A record
resource "cloudflare_record" "dns_record" {
  zone_id = data.cloudflare_zones.cf_zones.zones[0].id
  name    = "storybooks${terraform.workspace == "prod" ? "" : "-${terraform.workspace}"}"
  value   = google_compute_address.ip_address.address
  type    = "A"
  proxied = true
}
