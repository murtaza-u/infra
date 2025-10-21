resource "cloudflare_dns_record" "k3s_apisrv" {
  name    = var.cloudflare_dns_record
  proxied = false
  type    = "A"
  ttl     = 1 # auto
  content = oci_core_instance.srv_oci_instances[0].public_ip
  zone_id = var.cloudfare_zone_id
}
