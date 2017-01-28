variable "name" { }
variable "domain" { }
variable "aws_region" { }
variable "vpc_cidr" { }
variable "azs" { type = "list" }
variable "key_name" { }
variable "subnet_cidrs" { type = "list" }
variable "vpn_cidr" { }
variable "vpn_port" { }
variable "management_cluster_host_number" { }
variable "logging_cluster_host_number" { }

output "name" { value = "${var.name}" }
output "domain" { value = "${var.domain}" }
output "vpc_cidr" { value = "${var.vpc_cidr}" }
output "vpn_cidr" { value = "${var.vpn_cidr}" }
output "vpn_security_group_id" { value = "${module.vpn.security_group_id}" }
output "vpn_public_ip" { value = "${module.vpn.public_ip}" }
output "vpn_private_ip" { value = "${module.vpn.private_ip}" }
output "management_cluster_ips" { value = "${module.management-cluster.private_ips}" }
output "compute_cluster_ips" { value = "${module.compute-cluster.private_ips}" }
output "logging_cluster_ips" { value = "${module.logging-cluster.private_ips}" }
output "load_balancer_public_ip" { value = "${aws_eip.load-balancer.public_ip}"}

##
# Provide credentials for AWS from ~/.aws/credentials
# with the correct profile.
#
provider "aws" {
  profile = "${var.name}"
  region = "${var.aws_region}"
}

##
# Look up the latest AMI for Ubuntu 16
#
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  # Canonical
  owners = ["099720109477"]
}

##
# Create the network for our entire infrastructure.
#
module "vpc" {
  source = "./terraform/aws/vpc"
  name = "${var.name}"
  cidr = "${var.vpc_cidr}"
}

##
# Create subnets within our network.
#
module "subnet" {
  source = "./terraform/aws/subnet"
  name = "${var.name}-public"
  azs = "${var.azs}"
  vpc_id = "${module.vpc.id}"
  cidrs = "${var.subnet_cidrs}"
}

##
# Create Pritunl VPN to give access to private network from the internet.
#
module "vpn" {
  source = "./terraform/aws/vpn"
  name = "${var.name}-vpn"
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  vpc_id = "${module.vpc.id}"
  vpc_cidr = "${var.vpc_cidr}"
  subnet_id = "${element(module.subnet.ids, 1)}"
  cidr = "${var.vpn_cidr}"
  port = "${var.vpn_port}"
  route_table_id = "${module.subnet.route_table_id}"
}

##
# Create a high availability management cluster running:
#
# Consul (Distributed KV Store / Service Discovery)
# Nomad (Task Scheduler)
# Vault (Secrets Management)
# Fabio (Load Balancer)
#
# For large infrastructures it will makes sense to deploy
# these as multiple clusters, both for resiliance and for
# security. They are combined here to keep costs low.
#
module "management-cluster" {
  source = "./terraform/aws/cluster"
  name = "${var.name}-management-cluster"
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.small"
  key_name = "${var.key_name}"
  vpc_id = "${module.vpc.id}"
  vpc_cidr = "${var.vpc_cidr}"
  vpn_cidr = "${var.vpn_cidr}"
  subnet_ids = "${module.subnet.ids}"
  subnet_cidrs = "${var.subnet_cidrs}"
  size = "${length(var.subnet_cidrs)}"
  host_number = "${var.management_cluster_host_number}"
  policy_arn = "${aws_iam_policy.management-cluster.arn}"
}

##
# Create public IP for load balancer. This will be assigned to
# the first management cluster instance. Consul is configured
# such that if any management host dies, this "floating" IP will
# be transferred to a healthy node. All domains using this
# infrastructure should point to this IP.
#
resource "aws_eip" "load-balancer" {
  vpc = true
  instance = "${element(module.management-cluster.ids, 0)}"
}

##
# Create a logging cluster to run elasicsearch/logstash/kibana.
#
module "logging-cluster" {
  source = "./terraform/aws/cluster"
  name = "${var.name}-logging-cluster"
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  vpc_id = "${module.vpc.id}"
  vpc_cidr = "${var.vpc_cidr}"
  vpn_cidr = "${var.vpn_cidr}"
  subnet_ids = "${module.subnet.ids}"
  subnet_cidrs = "${var.subnet_cidrs}"
  size = "${length(var.subnet_cidrs)}"
  host_number = "${var.logging_cluster_host_number}"
}

##
# Create a compute cluster to run jobs scheduled by the management cluster.
#
module "compute-cluster" {
  source = "./terraform/aws/cluster"
  name = "${var.name}-compute-cluster"
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  vpc_id = "${module.vpc.id}"
  vpc_cidr = "${var.vpc_cidr}"
  vpn_cidr = "${var.vpn_cidr}"
  subnet_ids = "${module.subnet.ids}"
  subnet_cidrs = "${var.subnet_cidrs}"
  size = "${length(var.subnet_cidrs)}"
}

##
# Permissions needed for management cluster.
#
resource "aws_iam_policy" "management-cluster" {
  name = "${var.name}-management-cluster"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateAccessKey",
        "iam:CreateUser",
        "iam:PutUserPolicy",
        "iam:ListGroupsForUser",
        "iam:ListUserPolicies",
        "iam:ListAccessKeys",
        "iam:DeleteAccessKey",
        "iam:DeleteUserPolicy",
        "iam:RemoveUserFromGroup",
        "iam:DeleteUser",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:DescribeInstances"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}
