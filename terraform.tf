variable "name" { }
variable "domain" { }
variable "aws_region" { }
variable "ami" { }
variable "vpc_cidr" { }
variable "azs" { type = "list" }
variable "key_name" { }
variable "subnet_cidrs" { type = "list" }
variable "vpn_cidr" { }
variable "management_cluster_host_number" { }
variable "logging_cluster_host_number" { }

output "name" { value = "${var.name}" }
output "domain" { value = "${var.domain}" }
output "vpc_cidr" { value = "${var.vpc_cidr}" }
output "vpn_cidr" { value = "${var.vpn_cidr}" }
output "vpn_security_group_id" { value = "${module.vpn.security_group_id}" }
output "vpn_public_ip" { value = "${module.vpn.public_ip}" }
output "management_cluster_ips" { value = "${module.management-cluster.private_ips}" }
output "compute_cluster_ips" { value = "${module.compute-cluster.private_ips}" }
output "logging_cluster_ips" { value = "${module.logging-cluster.private_ips}" }
output "load_balancer_public_ip" { value = "${module.load-balancer.public_ip}"}
output "load_balancer_private_ip" { value = "${module.load-balancer.private_ip}"}

##
# Provide credentials for AWS from ~/.aws/credentials
# with the correct profile.
#
provider "aws" {
  profile = "${var.name}"
  region = "${var.aws_region}"
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
# Create OpenVPN box to give access to private network from the internet.
#
module "vpn" {
  source = "./terraform/aws/vpn"
  name = "${var.name}-vpn"
  ami = "${var.ami}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  vpc_id = "${module.vpc.id}"
  vpc_cidr = "${var.vpc_cidr}"
  subnet_id = "${element(module.subnet.ids, 1)}"
  cidr = "${var.vpn_cidr}"
  route_table_id = "${module.subnet.route_table_id}"
}

##
# Create a management cluster running Consul, Vault and Nomad.
#
module "management-cluster" {
  source = "./terraform/aws/cluster"
  name = "${var.name}-management-cluster"
  ami = "${var.ami}"
  instance_type = "t2.small"
  key_name = "${var.key_name}"
  vpc_id = "${module.vpc.id}"
  vpc_cidr = "${var.vpc_cidr}"
  vpn_cidr = "${var.vpn_cidr}"
  subnet_ids = "${module.subnet.ids}"
  subnet_cidrs = "${var.subnet_cidrs}"
  size = "${length(var.subnet_cidrs)}"
  host_number = "${var.management_cluster_host_number}"
  policy_arn = "${aws_iam_policy.vault.arn}"
}

##
# Create a logging cluster to run elasicsearch/logstash/kibana.
#
module "logging-cluster" {
  source = "./terraform/aws/cluster"
  name = "${var.name}-logging-cluster"
  ami = "${var.ami}"
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
  ami = "${var.ami}"
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
# Create an instance to host our load balancer (fabio)
#
module "load-balancer" {
  source = "./terraform/aws/load-balancer"
  name = "${var.name}-load-balancer"
  ami = "${var.ami}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  vpc_id = "${module.vpc.id}"
  vpc_cidr = "${var.vpc_cidr}"
  vpn_cidr = "${var.vpn_cidr}"
  subnet_id = "${element(module.subnet.ids, 0)}"
}

##
# A policy to give Vault IAM management access.
#
resource "aws_iam_policy" "vault" {
  name = "${var.name}"
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
        "iam:DeleteUser"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}
