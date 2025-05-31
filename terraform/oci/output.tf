output "oci_instances" {
  value = {
    for i in oci_core_instance.srv_oci_instances : i.display_name => {
      public_ip  = i.public_ip
      private_ip = i.private_ip
    }
  }
  description = "OCI created instances"
}

output "oci_icds" {
  value = {
    identity_domain_id = oci_identity_domain.lab.id
    app_id             = oci_identity_domains_app.k3s_idp.id
    oidc_issuer_url    = "https://identity.oraclecloud.com/"
    oidc_discovery_url = "${oci_identity_domains_app.k3s_idp.idcs_endpoint}/.well-known/openid-configuration"
    oidc_client_id     = oci_identity_domains_app.k3s_idp.name
  }
  description = "OCI ICDS"
}
