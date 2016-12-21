# infrastructure
> terraform, consul, vault, nomad, docker, fabio

## Setup
1. Install [AWSCLI], [Terraform], [Ansible] & [Tunnelblick].
2. Log into EC2 console, create a key pair titled "default". Download
   the key and add to your ssh-agent: `ssh-add /path/to/key.pem`
3. Ensure `~/.aws/credentials` has a profile with administrative
   access credentials that matches `name` in `terraform.tfvars`
4. Provision your infrastructure: `terraform apply`
5. Enable SSH access to VPN: `bin/enable-vpn-ssh`
6. Provision VPN: `bin/provision-vpn`
7. Get VPN configuration: `bin/fetch-admin-ovpn > vpn.ovpn`
8. Disable SSH access to VPN: `bin/disable-vpn-ssh`
9. Connect to VPN (using `vpn.ovpn`).
10. Provision Management Cluster: `bin/provision-management-cluster`
11. Provision Compute Cluster: `bin/provision-compute-cluster`
12. Initialize Vault: `bin/initialize-vault` (save output securely)
13. Unseal Vault (3x): `bin/unseal-vault <key>`

## To Do
- Get SSL communication going for Vault and Consul.
- Get DNS resolution for .consul working over VPN
- Get OpenVPN using Vault for PKI (aka ditch easy-rsa)
- Test Nomad/Vault integration on jobs
- Ditch Ansible for shell scripts integrated with Terraform?
- Hook up Fabio for a load balancer

## Tests
- Confirm Consul cluster is up by running `consul members` on any of the
  management cluster nodes.
- Confirm Consul is running w/ http://<any-management-cluster-ip>:8500
- Confirm Consul/Vault integration is working by sshing to any management
  cluster node and running `dig vault.service.consul`.
- Incrementally take out Vault instances w/ `systemctl stop vault` on
  any of the management cluster nodes and watch Consul fail over by
  running `dig active.vault.service.consul` (restarting service will require
  unsealing again).
- Test running job on nomad:
  1. scp services/proxy/job.nomad to any management cluster machine
  2. ssh to management cluster and run `nomad run job.nomad`
  3. get ip/port of service by running `dig SRV test-proxy-proxy.service.consul`
  5. browse to running service using ip/port from commands above
  6. check consul web ui--service should be there

[AWSCLI]: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
[Terraform]: https://www.terraform.io/downloads.html
[Ansible]: http://docs.ansible.com/ansible/intro_installation.html#latest-releases-via-pip
[Tunnelblick]: https://tunnelblick.net/downloads.html
