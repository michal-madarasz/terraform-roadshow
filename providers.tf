##
# Providers
##

terraform {
  required_version = ">= 0.14.0"
  required_providers {

    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.51.1"
    }

  }
}

provider "openstack" {
  auth_url         = var.os_auth_url
  domain_name      = "Default"
  user_domain_name = "Default"
  user_name        = var.os_username
  password         = var.os_password
  region           = var.os_region
  tenant_id        = var.os_project_id
  use_octavia      = true
}