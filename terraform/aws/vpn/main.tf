##
# This module manages a "split tunneling" VPN which gives connected clients
# access to the private network in our VPC. Being connected to this VPN does
# *not* mean regular internet traffic passes through AWS.
#
variable "name" { }
variable "vpc_id" { }
variable "vpc_cidr" { }
variable "ami" { }
variable "instance_type" { }
variable "key_name" { }
variable "subnet_id" { }
variable "route_table_id" { }
variable "cidr" { }
variable "port" { }

output "id" { value = "${aws_instance.host.id}" }
output "private_ip" { value = "${aws_instance.host.private_ip}" }
output "public_ip" { value = "${aws_instance.host.public_ip}" }
output "security_group_id" { value = "${aws_security_group.main.id}" }

resource "aws_instance" "host" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  subnet_id = "${var.subnet_id}"
  vpc_security_group_ids = [
    "${aws_security_group.main.id}"
  ]
  tags {
    Name = "${var.name}"
  }
  source_dest_check = false
}

##
# Control network access.
#
resource "aws_security_group" "main" {
  vpc_id = "${var.vpc_id}"
  name = "${var.name}"
  tags {
    Name = "${var.name}"
  }
  // allow all outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  // allow all inbound communication within the vpn/vpc
  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "${var.vpc_cidr}",
      "${var.cidr}"
    ]
  }
  // allow inbound vpn connections from anywhere
  ingress {
    protocol = "udp"
    from_port = "${var.port}"
    to_port = "${var.port}"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  lifecycle {
    create_before_destroy = true
  }
}

##
# Enable hosts on our network to communicate directly
# with connected VPN clients.
#
resource "aws_route" "main" {
  route_table_id = "${var.route_table_id}"
  destination_cidr_block = "${var.cidr}"
  instance_id = "${aws_instance.host.id}"
}
