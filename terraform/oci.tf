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

resource "oci_identity_policy" "lab_compartment_administrator_policy" {
  compartment_id = oci_identity_compartment.lab.id
  description    = "Allow Lab domain administrators to manage all resources in the Lab compartment"
  name           = "lab_compartment_administrator_policy"
  statements = [
    "Allow group '${oci_identity_domain.lab.display_name}'/'Domain_Administrators' to manage all-resources in compartment ${oci_identity_compartment.lab.name}"
  ]
}

resource "oci_core_vcn" "movingbunkerlab" {
  compartment_id = oci_identity_compartment.lab.id
  cidr_block     = "10.0.0.0/16"
  display_name   = "MovingBunkerLab"
  is_ipv6enabled = false
}

resource "oci_core_internet_gateway" "movingbunkerlab_kubernetes_cluster" {
  compartment_id = oci_identity_compartment.lab.id
  vcn_id         = oci_core_vcn.movingbunkerlab.id
  enabled        = true
  display_name   = "KubernetesClusterIGW"
}

resource "oci_core_route_table" "movingbunkerlab_kubernetes_cluster" {
  compartment_id = oci_identity_compartment.lab.id
  vcn_id         = oci_core_vcn.movingbunkerlab.id
  display_name   = "KubernetesCluster"
  route_rules {
    network_entity_id = oci_core_internet_gateway.movingbunkerlab_kubernetes_cluster.id
    description       = "Connect to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "kubernetes_cluster" {
  compartment_id = oci_identity_compartment.lab.id
  vcn_id         = oci_core_vcn.movingbunkerlab.id
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
      max = 80
      min = 80
    }
  }
  ingress_security_rules {
    description = "Allow TCP port 443 (https)"
    source      = "0.0.0.0/0"
    protocol    = "6" # tcp
    tcp_options {
      max = 443
      min = 443
    }
  }
  ingress_security_rules {
    description = "Allow TCP port 22 (ssh)"
    source      = "0.0.0.0/0"
    protocol    = "6" # tcp
    tcp_options {
      max = 22
      min = 22
    }
  }
}

data "oci_identity_availability_domains" "kubernetes_cluster" {
  compartment_id = oci_identity_compartment.lab.id
}

resource "oci_core_subnet" "kubernetes_cluster" {
  cidr_block                 = "10.0.0.0/24"
  compartment_id             = oci_identity_compartment.lab.id
  vcn_id                     = oci_core_vcn.movingbunkerlab.id
  route_table_id             = oci_core_route_table.movingbunkerlab_kubernetes_cluster.id
  display_name               = "KubernetesCluster"
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  security_list_ids          = [oci_core_security_list.kubernetes_cluster.id]
  availability_domain        = data.oci_identity_availability_domains.kubernetes_cluster.availability_domains[0].name
}

data "oci_core_images" "oracle_linux" {
  compartment_id   = oci_identity_compartment.lab.id
  operating_system = "Oracle Linux"
  shape            = var.oci_instance_shape
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"
}

resource "oci_core_instance" "srv_oci_instances" {
  count               = 1
  compartment_id      = oci_identity_compartment.lab.id
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
