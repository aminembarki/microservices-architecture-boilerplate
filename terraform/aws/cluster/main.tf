##
# This modules manages a cluster providing highly available
# instances of Consul, Vault and Nomad for usaged across the
# entire infrastructure.
#
variable "name" { }
variable "vpc_id" { }
variable "vpc_cidr" { }
variable "ami" { }
variable "instance_type" { }
variable "key_name" { }
variable "subnet_ids" { type = "list" }
variable "size" { }
variable "policy_arn" { default = "" }

output "ips" {
  value = ["${aws_instance.host.*.private_ip}"]
}

resource "aws_instance" "host" {
  count = "${var.size}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  subnet_id = "${element(var.subnet_ids, count.index)}"
  vpc_security_group_ids = [
    "${aws_security_group.main.id}",
  ]
  iam_instance_profile = "${aws_iam_instance_profile.main.name}"
  tags {
    Name = "${var.name}-${count.index}"
  }
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
  // allow outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  // allow inbound communication on all ports within the vpc only
  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "${var.vpc_cidr}"
    ]
  }
  lifecycle {
    create_before_destroy = true
  }
}

##
# A role to receive permissions from the IAM policy system.
#
resource "aws_iam_role" "main" {
  name = "${var.name}"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {"AWS": "*"},
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

##
# Associate role with the created instance.
#
resource "aws_iam_instance_profile" "main" {
  name = "${var.name}"
  roles = ["${aws_iam_role.main.name}"]
}

##
# Attach policy to the role, either from outside the module or a dummy
# empty policy from within (to allow future-proof replacements).
#
resource "aws_iam_role_policy_attachment" "main" {
  role = "${aws_iam_role.main.name}"
  policy_arn = "${var.policy_arn != "" ? var.policy_arn : aws_iam_policy.main.arn}"
}


##
# Empty policy, applied when one outside the module isn't supplied.
#
resource "aws_iam_policy" "main" {
  name = "${var.name}"
  path = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeInstance",
      "Resource": "*"
    }
  ]
}
EOF
}
