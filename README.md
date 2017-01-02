# infrastructure
> terraform, consul, vault, nomad, docker, fabio, elasticsearch, logstash, kibana, elastalert

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
10. Provision Logging Cluster: `bin/provision-logging-cluster`
11. Provision Compute Cluster: `bin/provision-compute-cluster`
12. Provision Load Balancer: `bin/provision-load-balancer`
13. Initialize Vault: `bin/initialize-vault` (save output securely)
14. Unseal Vault (3x): `bin/unseal-vault <key>`

## To Do
- Get log shipping system set up (elastic stack)
- Confirm Fabio working for SSL
- Hook up fabio certificate store for SSL termination
- Get SSL communication going for Vault and Consul.
- Get OpenVPN using Vault for PKI (aka ditch easy-rsa)
- Lock down consul a bit:
  - https://www.mauras.ch/securing-consul.html

## Tests
- Confirm Consul cluster is up by running `consul members` on any of the
  management cluster nodes
- Confirm Consul is being used for DNS locally while connected to VPN
  with `dig consul.service.consul`
- Confirm Consul UI is up: http://consul.service.consul:8500
- Confirm Consul/Vault integration: `dig vault.service.consul`.
- Incrementally take out Vault instances w/ `systemctl stop vault` on
  any of the management cluster nodes and watch Consul fail over by
  running `dig vault.service.consul` (restarting service will require
  unsealing again).
- Test running job on nomad:
  1. `scp services/proxy/job.nomad ubuntu@nomad.service.consul:~/`
  2. `ssh ubuntu@nomad.service.consul "nomad run job.nomad"`
  3. check http://consul.service.consul:8500 for new service
  3. check http://fabio.service.consul:9998 to see the routing table updated
  4. check that fabio is forwarding with the following:
     ```
     telnet fabio.service.consul 80
     GET / HTTP/1.1
     HOST: gs.loc
     <hit enter>
     ctrl+]
     quit
     ```

[AWSCLI]: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
[Terraform]: https://www.terraform.io/downloads.html
[Ansible]: http://docs.ansible.com/ansible/intro_installation.html#latest-releases-via-pip
[Tunnelblick]: https://tunnelblick.net/downloads.html
