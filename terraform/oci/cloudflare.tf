resource "cloudflare_dns_record" "example_dns_record" {
  name    = "k3s.murtazau.xyz"
  proxied = false
  type    = "A"
  ttl     = 1 # auto
  content = oci_core_instance.srv_oci_instances[0].public_ip
  zone_id = var.cloudfare_zone_id

  # zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
  # comment = "Domain verification record"
  # content = "198.51.100.4"
  # name    = "example.com"
  # proxied = true
  # settings = {
  #   ipv4_only = true
  #   ipv6_only = true
  # }
  # tags = ["owner:dns-team"]
  # ttl  = 3600
  # type = "A"
}
