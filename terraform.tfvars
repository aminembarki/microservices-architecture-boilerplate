# A name (used as a prefix in many places) for this infrastructure.
name = "axioma"

# The primary domain associated with this infrastructure.
domain = "axioma.io"

# The AWS region where this infrastructure resides.
aws_region = "us-east-1"

# This is the name of the default keypair key to use for all instances.
key_name = "default"

# This is the network all of our services are hosted in.
vpc_cidr = "10.100.0.0/16"

# This is the network our OpenVPN instance will use.
vpn_cidr = "10.110.0.0/16"

# Default AMI (Ubuntu 16.04)
ami = "ami-40d28157"

# Default instance type
instance_type = "t2.micro"

# This is all of the availability zones we will create subnets for
azs = [
  "us-east-1a",
  "us-east-1c",
  "us-east-1e"
]

# Subnets to define within the VPC, one for each AZ.
subnet_cidrs = [
  "10.100.0.0/24",
  "10.100.1.0/24",
  "10.100.2.0/24"
]

# This defines a static host number to use for management
# cluster instance private ips. For the subnets above, this
# would yield instances running at 10.100.0.10, 10.100.1.10
# and 10.100.2.10
management_cluster_host_number = 10
