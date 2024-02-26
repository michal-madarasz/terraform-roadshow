##
# Self-signed Certs
##

resource "openstack_keymanager_secret_v1" "tls_secret" {
  name                     = "${var.resource_prefix}tls_secret"
  payload                  = filebase64("./certs/server.p12")
  payload_content_type     = "application/octet-stream"
  payload_content_encoding = "base64"
}


##
# HTTP Servers
##

resource "openstack_compute_instance_v2" "http_server" {
  name        = "${var.resource_prefix}http_server_${count.index}"
  count       = var.instance_nb
  image_name  = var.image_name
  flavor_name = var.instance_type
  network {
    name = openstack_networking_network_v2.lb_network.name
  }
  user_data       = <<EOF
#!/bin/bash
echo '-- user data begins --'
sudo apt-get update
sudo apt-get install -y nginx
echo '# LB Test
<html>
  <head>
    <title>
      LB Member ${count.index}
    </title>
  </head>
  <body>
    <p>Hit LB Member ${count.index}</p>
  </body>
</html>' | sudo tee /var/www/html/index.html
echo '-- user data end --'
EOF
  depends_on      = [openstack_networking_router_interface_v2.lb_router_priv_iface]
  security_groups = ["${openstack_networking_secgroup_v2.secgroup.name}"]
}


##
# Networking
##

data "openstack_networking_network_v2" "ext_net" {
  name     = var.external_network
  external = true
}

resource "openstack_networking_secgroup_v2" "secgroup" {
  name                 = "${var.resource_prefix}secgroup"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_v4_dns_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 53
  port_range_max    = 53
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_v4_http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_v4_https_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_v4_dns_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 53
  port_range_max    = 53
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_v4_http_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_v4_https_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_network_v2" "lb_network" {
  name           = "${var.resource_prefix}network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "lb_subnet" {
  name            = "${var.resource_prefix}subnet"
  network_id      = openstack_networking_network_v2.lb_network.id
  cidr            = "10.0.0.0/24"
  gateway_ip      = "10.0.0.254"
  dns_nameservers = ["1.1.1.1", "1.0.0.1"]
  ip_version      = 4
}

resource "openstack_networking_router_v2" "lb_router" {
  name                = "${var.resource_prefix}router"
  external_network_id = data.openstack_networking_network_v2.ext_net.id
}

resource "openstack_networking_floatingip_v2" "lb_fip" {
  description = "${var.resource_prefix}fip"
  pool        = data.openstack_networking_network_v2.ext_net.name
}

resource "openstack_networking_router_interface_v2" "lb_router_priv_iface" {
  router_id = openstack_networking_router_v2.lb_router.id
  subnet_id = openstack_networking_subnet_v2.lb_subnet.id
}

resource "openstack_networking_floatingip_associate_v2" "association" {
  floating_ip = openstack_networking_floatingip_v2.lb_fip.address
  port_id     = openstack_lb_loadbalancer_v2.lb.vip_port_id
}


##
# Loadbalancers
##

resource "openstack_lb_loadbalancer_v2" "lb" {
  name               = "${var.resource_prefix}lb"
  vip_network_id     = openstack_networking_network_v2.lb_network.id
  vip_subnet_id      = openstack_networking_subnet_v2.lb_subnet.id
  security_group_ids = ["${openstack_networking_secgroup_v2.secgroup.id}"]
}

resource "openstack_lb_listener_v2" "https_listener" {
  name                      = "${var.resource_prefix}https_listener"
  protocol                  = "TERMINATED_HTTPS"
  protocol_port             = 443
  loadbalancer_id           = openstack_lb_loadbalancer_v2.lb.id
  default_tls_container_ref = openstack_keymanager_secret_v1.tls_secret.secret_ref
}

resource "openstack_lb_pool_v2" "main_pool" {
  name        = "${var.resource_prefix}main_pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.https_listener.id
}

resource "openstack_lb_member_v2" "main_member" {
  name          = "${var.resource_prefix}member_${count.index}"
  count         = var.instance_nb
  protocol_port = 80
  pool_id       = openstack_lb_pool_v2.main_pool.id
  address       = openstack_compute_instance_v2.http_server[count.index].access_ip_v4
  subnet_id     = openstack_networking_subnet_v2.lb_subnet.id
}

resource "openstack_lb_monitor_v2" "monitor" {
  name        = "${var.resource_prefix}monitor"
  pool_id     = openstack_lb_pool_v2.main_pool.id
  type        = "HTTP"
  url_path    = "/index.html"
  delay       = 5
  timeout     = 10
  max_retries = 5
}