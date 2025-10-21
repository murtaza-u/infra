data "oci_identity_compartments" "homelab" {
  compartment_id = var.oci_parent_compartment_id
  name           = "homelab"
}

resource "oci_identity_domain" "homelab" {
  compartment_id            = data.oci_identity_compartments.homelab.compartments[0].id
  description               = "homelab domain"
  display_name              = "homelab"
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

resource "oci_identity_policy" "homelab_compartment_administrator_policy" {
  compartment_id = data.oci_identity_compartments.homelab.compartments[0].id
  description    = "Allow homelab domain administrators to manage all resources in the homelab compartment"
  name           = "homelab_compartment_administrator_policy"
  statements = [
    "Allow group '${data.oci_identity_compartments.homelab.compartments[0].name}'/'Domain_Administrators' to manage all-resources in compartment ${data.oci_identity_compartments.homelab.compartments[0].name}"
  ]
}

resource "oci_core_vcn" "movingbunkerhomelab" {
  compartment_id = data.oci_identity_compartments.homelab.compartments[0].id
  cidr_block     = "10.0.0.0/16"
  display_name   = "MovingBunkerhomelab"
  is_ipv6enabled = false
}

resource "oci_core_internet_gateway" "movingbunkerhomelab_kubernetes_cluster" {
  compartment_id = data.oci_identity_compartments.homelab.compartments[0].id
  vcn_id         = oci_core_vcn.movingbunkerhomelab.id
  enabled        = true
  display_name   = "KubernetesClusterIGW"
}

resource "oci_core_route_table" "movingbunkerhomelab_kubernetes_cluster" {
  compartment_id = data.oci_identity_compartments.homelab.compartments[0].id
  vcn_id         = oci_core_vcn.movingbunkerhomelab.id
  display_name   = "KubernetesCluster"
  route_rules {
    network_entity_id = oci_core_internet_gateway.movingbunkerhomelab_kubernetes_cluster.id
    description       = "Connect to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "kubernetes_cluster" {
  compartment_id = data.oci_identity_compartments.homelab.compartments[0].id
  vcn_id         = oci_core_vcn.movingbunkerhomelab.id
  display_name   = "Allow http, https & ssh inbound and ALL outbound"
  egress_security_rules {
    description = "Allow all traffic"
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  ingress_security_rules {
    description = "Allow TCP port 80 (http)"
    source      = "0.0.0.0/0"
    protocol    = "6" # tcp
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    description = "Allow TCP port 443 (https)"
    source      = "0.0.0.0/0"
    protocol    = "6" # tcp
    tcp_options {
      min = 443
      max = 443
    }
  }
  ingress_security_rules {
    description = "Allow TCP port 22 (ssh)"
    source      = "0.0.0.0/0"
    protocol    = "6" # tcp
    tcp_options {
      min = 22
      max = 22
    }
  }
}

data "oci_identity_availability_domains" "kubernetes_cluster" {
  compartment_id = data.oci_identity_compartments.homelab.compartments[0].id
}

resource "oci_core_subnet" "kubernetes_cluster" {
  cidr_block                 = "10.0.0.0/24"
  compartment_id             = data.oci_identity_compartments.homelab.compartments[0].id
  vcn_id                     = oci_core_vcn.movingbunkerhomelab.id
  route_table_id             = oci_core_route_table.movingbunkerhomelab_kubernetes_cluster.id
  display_name               = "KubernetesCluster"
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  security_list_ids          = [oci_core_security_list.kubernetes_cluster.id]
  availability_domain        = data.oci_identity_availability_domains.kubernetes_cluster.availability_domains[0].name
}

##########
## NSGs ##
##########
resource "oci_core_network_security_group" "k3s_node" {
  compartment_id = data.oci_identity_compartments.homelab.compartments[0].id
  vcn_id         = oci_core_vcn.movingbunkerhomelab.id
  display_name   = "All K3S node"
}

resource "oci_core_network_security_group" "k3s_server_node" {
  compartment_id = data.oci_identity_compartments.homelab.compartments[0].id
  vcn_id         = oci_core_vcn.movingbunkerhomelab.id
  display_name   = "K3S server node"
}

resource "oci_core_network_security_group" "k3s_agent_node" {
  compartment_id = data.oci_identity_compartments.homelab.compartments[0].id
  vcn_id         = oci_core_vcn.movingbunkerhomelab.id
  display_name   = "K3S agent node"
}

resource "oci_core_network_security_group_security_rule" "kubernetes_api" {
  network_security_group_id = oci_core_network_security_group.k3s_server_node.id
  direction                 = "INGRESS"
  protocol                  = "6" # tcp
  description               = "Kubernetes API"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubelet_metrics" {
  network_security_group_id = oci_core_network_security_group.k3s_node.id
  direction                 = "INGRESS"
  protocol                  = "6" # tcp
  description               = "Kubelet metrics"
  source                    = oci_core_network_security_group.k3s_node.id
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "flannel_cni_vxlan" {
  network_security_group_id = oci_core_network_security_group.k3s_node.id
  direction                 = "INGRESS"
  protocol                  = "17" # udp
  description               = "Flannel CNI with VXLAN"
  source                    = oci_core_network_security_group.k3s_node.id
  source_type               = "NETWORK_SECURITY_GROUP"
  udp_options {
    destination_port_range {
      min = 8472
      max = 8472
    }
  }
}

data "oci_core_images" "oracle_linux" {
  compartment_id   = data.oci_identity_compartments.homelab.compartments[0].id
  operating_system = "Oracle Linux"
  shape            = var.oci_instance_shape
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"
}

resource "oci_core_instance" "srv_oci_instances" {
  count               = 2
  compartment_id      = data.oci_identity_compartments.homelab.compartments[0].id
  availability_domain = oci_core_subnet.kubernetes_cluster.availability_domain
  shape               = var.oci_instance_shape
  shape_config {
    memory_in_gbs = "12"
    ocpus         = "2"
  }
  create_vnic_details {
    assign_ipv6ip             = false
    assign_private_dns_record = false
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.kubernetes_cluster.id
    nsg_ids = [
      oci_core_network_security_group.k3s_node.id,
      count.index == 0 ? oci_core_network_security_group.k3s_server_node.id : oci_core_network_security_group.k3s_agent_node.id
    ]
  }
  display_name = "srv-oci-${count.index}"
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }
  source_details {
    source_id               = data.oci_core_images.oracle_linux.images[0].id
    source_type             = "image"
    boot_volume_size_in_gbs = "100"
    boot_volume_vpus_per_gb = "10"
  }
  preserve_boot_volume = false
  metadata = {
    ssh_authorized_keys = var.install_ssh_pub_key
  }
  lifecycle {
    ignore_changes = [
      source_details[0].source_id
    ]
  }
}

resource "oci_identity_domains_setting" "homelab_domain_settings" {
  idcs_endpoint              = oci_identity_domain.homelab.url
  csr_access                 = "none"
  schemas                    = ["urn:ietf:params:scim:schemas:oracle:idcs:Settings"]
  setting_id                 = "Settings"
  signing_cert_public_access = true
}

resource "oci_identity_domains_app" "k3s_idp" {
  based_on_template {
    value         = "CustomWebAppTemplateId"
    well_known_id = "CustomWebAppTemplateId"
  }
  display_name  = "K3S IdP"
  idcs_endpoint = oci_identity_domain.homelab.url
  schemas = [
    "urn:ietf:params:scim:schemas:oracle:idcs:App",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags"
  ]
  description             = "Kubernetes OIDC Authentication"
  show_in_my_apps         = true
  active                  = true
  access_token_expiry     = 3600
  all_url_schemes_allowed = true
  allow_access_control    = false
  allow_offline           = true
  allowed_grants          = ["authorization_code", "client_credentials"]
  audience                = "k3s"
  bypass_consent          = false
  client_ip_checking      = "anywhere"
  client_type             = "confidential"
  is_oauth_client         = true
  login_mechanism         = "OIDC"
  redirect_uris           = ["http://localhost:8000", "http://localhost:18000"]
  contact_email_address   = "murtaza@murtazau.xyz"
  product_name            = "K3S IdP"
  product_logo_url        = "https://raw.githubusercontent.com/kubernetes/kubernetes/refs/heads/master/logo/logo.svg"
}

resource "null_resource" "mark_instance_new" {
  count = length(oci_core_instance.srv_oci_instances)
  triggers = {
    instance_id = oci_core_instance.srv_oci_instances[count.index].id
  }
  provisioner "local-exec" {
    command = <<EOF
    mkdir -p state
    touch state/${oci_core_instance.srv_oci_instances[count.index].display_name}.new
    EOF
  }
}
