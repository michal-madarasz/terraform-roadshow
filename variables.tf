##
# Other
##

variable "resource_prefix" {
  type        = string
  description = "the prefix that is used for all the created resources"
  default     = "roadshow_"
}


##
# Openstack Auth
##

variable "os_auth_url" {
  type        = string
  description = "openstack auth url"
  default     = "https://auth.cloud.ovh.net:443/"
}

variable "os_username" {
  type        = string
  description = "openstack user name"
}

variable "os_password" {
  type        = string
  description = "openstack password"
}

variable "os_region" {
  type        = string
  description = "the openstack region on which the infrastructure will be deployed"
}

variable "os_project_id" {
  type        = string
  description = "openstack project id"
}


##
# Infra
##

variable "image_name" {
  type        = string
  description = "The image used for the instances"
  default     = "Debian 11"
}

variable "instance_type" {
  type        = string
  description = "the instances type"
  default     = "b3-8"
}

variable "external_network" {
  type        = string
  description = "The name of the network that is used to connect a private network to internet"
  default     = "Ext-Net"
}

variable "instance_nb" {
  type        = number
  description = "The number of http instance that will be answering to http requests behind the load balancer"
  default     = 2
}
