##
# This modules manages a load balancing instance.
#
variable "name" { }
variable "vpc_id" { }
variable "vpc_cidr" { }
variable "vpn_cidr" { }
variable "ami" { }
variable "instance_type" { }
variable "key_name" { }
variable "subnet_id" { }

output "public_ip" { value = "${aws_instance.host.public_ip}" }
output "private_ip" { value = "${aws_instance.host.private_ip}" }

resource "aws_instance" "host" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  subnet_id = "${var.subnet_id}"
  vpc_security_group_ids = [
    "${aws_security_group.main.id}",
  ]
  tags {
    Name = "${var.name}"
  }
}
resource "aws_eip" "main" {
  instance = "${aws_instance.host.id}"
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
  // allow all inbound traffic within the vpn/vpc
  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "${var.vpc_cidr}",
      "${var.vpn_cidr}"
    ]
  }
  // allow http traffic inbound
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  // allow https traffic inbound
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  lifecycle {
    create_before_destroy = true
  }
}
