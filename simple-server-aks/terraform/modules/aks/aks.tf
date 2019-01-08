
resource "tls_private_key" "ssh-key" {
  algorithm   = "RSA"
}

resource "null_resource" "save-ssh-key" {
  triggers {
    key = "${tls_private_key.ssh-key.private_key_pem}"
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/.ssh
      echo "${tls_private_key.ssh-key.private_key_pem}" > ${path.module}/.ssh/aks_id_rsa
      chmod 0600 ${path.module}/.ssh/aks_id_rsa
EOF
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-${var.env}-${var.cluster_name}"
  location            = "${var.location}"
  resource_group_name = "${var.rg_name}"
  dns_prefix          = "${var.dns_prefix}"

  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
      key_data = "${trimspace(tls_private_key.ssh-key.public_key_openssh)} ubuntu@azure.com"
    }
  }

  agent_pool_profile {
    name            = "${var.agent_pool_name}"
    count           = "${var.agent_count}"
    vm_size         = "${var.vm_size}"
    os_type         = "Linux"
    os_disk_size_gb = "${var.os_disk_size_gb}"
  }

  service_principal {
    client_id     = "${var.service_principal_client_id}"
    client_secret = "${var.service_principal_client_secret}"
  }


  tags {
    Name        = "${var.prefix}-${var.env}-${var.cluster_name}"
    Environment = "${var.prefix}-${var.env}"
    Terraform   = "true"
  }
}
