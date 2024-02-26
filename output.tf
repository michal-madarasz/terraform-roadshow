##
# Outputs
##

output "lb_url" {
  value       = "https://${openstack_networking_floatingip_v2.lb_fip.address}"
  description = "The loadbalancer public url"
}