locals {
  grant_type    = "client_credentials"
  client_id     = data.oci_identity_domains_app.k3s_idp.name
  client_secret = data.oci_identity_domains_app.k3s_idp.client_secret
  scope         = "urn:opc:idm:t.security.client"
  access_token  = jsondecode(data.http.oidc_token.response_body).access_token
}

data "oci_identity_domain" "homelab" {
  domain_id = var.oci_identity_domain_id
}

data "oci_identity_domains_app" "k3s_idp" {
  app_id        = var.oci_identity_domain_app_id
  idcs_endpoint = data.oci_identity_domain.homelab.url
}

data "http" "oidc_token" {
  url    = "${data.oci_identity_domains_app.k3s_idp.idcs_endpoint}/oauth2/v1/token"
  method = "POST"
  request_headers = {
    Content-Type = "application/x-www-form-urlencoded"
    Accept       = "application/json"
  }
  request_body = "grant_type=${local.grant_type}&client_id=${local.client_id}&client_secret=${local.client_secret}&scope=${local.scope}"
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "non-200 status code returned"
    }
  }
}
