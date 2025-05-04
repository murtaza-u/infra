resource "oci_identity_compartment" "lab" {
  compartment_id = var.oci_parent_compartment_id
  description    = "Lab environment"
  name           = "lab"
}

resource "oci_identity_domain" "lab" {
  compartment_id            = oci_identity_compartment.lab.id
  description               = "Lab domain"
  display_name              = "Lab"
  home_region               = var.oci_region
  license_type              = "free"
  admin_email               = var.oci_domain_admin_email
  admin_first_name          = "Murtaza"
  admin_last_name           = "Udaipurwala"
  admin_user_name           = "murtaza"
  is_hidden_on_login        = false
  is_primary_email_required = false
  is_notification_bypassed  = false
}

resource "oci_identity_domains_group" "gha_terraform_lab_runners" {
  display_name  = "gha_terraform_lab_runners"
  idcs_endpoint = oci_identity_domain.lab.url
  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:Group",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:dynamic:Group",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:group:Group",
  ]
  urnietfparamsscimschemasoracleidcsextensiongroup_group {
    description = "Manages OCI instances in the Lab compartment"
  }
  members {
    value = oci_identity_domains_user.gha_terraform_lab_runner.id
    type  = "User"
  }
}

resource "oci_identity_domains_user" "gha_terraform_lab_runner" {
  idcs_endpoint = oci_identity_domain.lab.url
  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:userState:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:capabilities:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:user:User"
  ]
  user_name    = "gha_terraform_lab_runner"
  description  = "Manages OCI instances in the Lab compartment"
  display_name = "GitHub Action Terraform Lab Runner"
  name {
    given_name  = "gha_terraform_lab_runner"
    family_name = "(GitHub Action Terraform Lab Runner)"
  }
  urnietfparamsscimschemasoracleidcsextensioncapabilities_user {
    can_use_api_keys                 = true
    can_use_auth_tokens              = false
    can_use_console_password         = false
    can_use_customer_secret_keys     = false
    can_use_db_credentials           = false
    can_use_oauth2client_credentials = false
    can_use_smtp_credentials         = false
  }
}

resource "oci_identity_policy" "gha_terraform_lab_runner_policy" {
  compartment_id = oci_identity_compartment.lab.id
  description    = "Allow managing OCI instances (VMs)"
  name           = "gha_terraform_lab_runner_policy"
  statements = [
    "Allow group '${oci_identity_domain.lab.display_name}'/'${oci_identity_domains_group.gha_terraform_lab_runners.display_name}' to manage instances in compartment ${oci_identity_compartment.lab.name}"
  ]
}

resource "oci_identity_policy" "lab_compartment_administrator_policy" {
  compartment_id = oci_identity_compartment.lab.id
  description    = "Allow Lab domain administrators to manage all resources in the Lab compartment"
  name           = "lab_compartment_administrator_policy"
  statements = [
    "Allow group '${oci_identity_domain.lab.display_name}'/'Domain_Administrators' to manage all-resources in compartment ${oci_identity_compartment.lab.name}"
  ]
}

resource "oci_identity_domains_api_key" "api_key" {
  idcs_endpoint = oci_identity_domain.lab.url
  key           = var.oci_gha_terraform_runner_api_pubkey
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:apikey"]
  description   = "GitHub Actions"
  user {
    ocid  = oci_identity_domains_user.gha_terraform_lab_runner.ocid
    value = oci_identity_domains_user.gha_terraform_lab_runner.id
  }
}
