# modern-microservices-architecture-boilerplate
> a foundational sea of complexity

All the cool kids are making microservices these days and you want in too?

## Setup
1. Install [AWSCLI], [Terraform], [Ansible] & [Pritunl].
2. Log into AWS EC2 console, create a key pair titled "default".
   Download the key and add to your ssh-agent: `ssh-add /path/to/key.pem`
3. Ensure `~/.aws/credentials` has a profile with administrative
   access keys that match `name` in `terraform.tfvars`
4. Provision your infrastructure: `terraform apply`
5. Copy the private ip of the VPN in the final terraform output
6. Enable public management of VPN: `bin/enable-vpn-management`
7. Provision VPN: `bin/provision-vpn`
8. Set up VPN: `bin/manage-vpn` ([pritunl docs]) # TODO: automate using API?
   * Accept the invalid SSL certificate warning in browser
   * Log in as pritunl/pritunl
   * Set new administrative user/password
   * Click users in top nav
     * Click add organization and fill out form
     * Click add user and fill out form
   * Click servers in top nav
     * Click add server and fill out form
         * Set VPN port to match `vpn_port` in `terraform.tfvars`
         * Set Virtual Network to match `vpn_cidr` in `terraform.tfvars`
         * Set DNS to the private IP of the VPN (paste from step #5).
           This will give connected operators and developers the ability
           to resolve `&#42;.service.consul` domains.
     * Click add route and enter the `vpc_cidr` from `terraform.tfvars`
     * Click remove route for `0.0.0.0/0` (makes vpn a [split tunnel])
     * Click attach organization
     * Click start server
   * Click users in top nav
   * Click chain icon next to your user for "temporary profile links"
   * Copy "Temporary uri link for Pritunl Client"
9. Open Pritunl client, import profile and connect
10. Disable public management of VPN: `bin/disable-vpn-management`
11. Provision management cluster: `bin/provision-management-cluster`
12. Provision logging cluster: `bin/provision-logging-cluster`
13. Provision compute cluster: `bin/provision-compute-cluster`
14. Initialize vault: `bin/initialize-vault` (save output securely)
15. Unseal vault (3x): `bin/unseal-vault <key>`

## To Do
- Get log shipping system set up (elastic stack)
- Confirm Fabio working for SSL
- Hook up fabio certificate store for SSL termination
- Get SSL communication going for Vault and Consul.
- Lock down consul a bit:
  - https://www.mauras.ch/securing-consul.html
- Confirm that dnsmasq is the correct approach for integration with consul
  - Specifically with regards to caching.

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
- confirm HA rollover for fabio by stopping fabio on any management cluster
  instance and watching EIP association change in aws console

## Technologies used

#### AWS
High level explainer to follow.

#### Terraform
High level explainer to follow.

### Ansible
High level explainer to follow.

#### Pritunl
High level explainer to follow.

#### Consul
High level explainer to follow.

#### Vault
High level explainer to follow.

#### Nomad
High level explainer to follow.

#### Docker
High level explainer to follow.

#### Fabio
High level explainer to follow.

### Elasticsearch
High level explainer to follow.

### Kibana
High level explainer to follow.

[AWSCLI]: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
[Terraform]: https://www.terraform.io/downloads.html
[Ansible]: http://docs.ansible.com/ansible/intro_installation.html#latest-releases-via-pip
[Pritunl]: https://pritunl.com
[pritunl docs]: https://docs.pritunl.com/docs/connecting
[split tunnel]: https://en.wikipedia.org/wiki/Split_tunneling
