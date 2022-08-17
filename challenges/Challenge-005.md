# Challenge - 005
![logo](https://clutchco-static.s3.amazonaws.com/s3fs-public/logos/f6c6bbce275df2b17b9f93614e5d4a9a.png?VersionId=UIElRv4d9sdz1zf_yyHVozLKMMU7C.YF)
## Contents
- [Cloud (Challenge 005)](#cloud)
- [Setup and Run (Challenge 001-002)](#setup-and-run)
- [Mounting a staking pool (Challenge 003)](#mounting-a-staking-pool)
- [Monitoring (Challenge 004)](#monitoring)
- [Additionally (Notes from challenge 001-004) ](#additionally)

## Cloud 

AWS was used as a cloud provider.

Basic costs:
- EC instance m5.2xlarge (validator node) - 0.46$/h*24*30 = 331.2$
- Volume size 500G = 0.119$*500 = 59.5$

Total: **390.7**$*/m

**For the region eu-central (Frankfurt)*

Additional costs:
- EC instance t3.small  (monitoring) - 0,024$/h*24*30 = 17,28$
- Outgoing traffic 0.05$ per gigabyte with a volume of more than 150 GB*

**100 GB per month for free*

The infrastructure for servers is deployed using Terraform.

Terraform creates the following elements:

- monitoring_security_group
- validator_security_group
- ec2_validator_node
- ec2_monitoring_node
- aws_ebs_volume

[[Source](https://github.com/inc4/shardnet-ops/tree/main/terraform)]

<details><summary>main.tf</summary>

```

locals {
  env               = "dev"
  network           = "shardnet"
  ami_id            = "ami-0a5b5c0ea66ec560d"
  availability_zone = "eu-central-1c"
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Network     = "shardnet"
  }

}

resource "aws_key_pair" "this" {
  public_key = var.aws_key_pair_public_key
}

data "aws_vpc" "default" {
  default = true
}

module "monitoring_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/prometheus"
  version = "4.9.0"

  name   = "monitoring-sg"
  vpc_id = data.aws_vpc.default.id

  egress_rules        = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "ssh-tcp", "grafana-tcp"]
  ingress_with_source_security_group_id = [
    {
      from_port                = 9080
      to_port                  = 9080
      protocol                 = "tcp"
      description              = "Allow promtail port"
      source_security_group_id = module.validator_security_group.security_group_id
    },
    {
      from_port                = 3100
      to_port                  = 3100
      protocol                 = "tcp"
      description              = "Allow loki port"
      source_security_group_id = module.validator_security_group.security_group_id
    },
  ]
}

module "validator_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/elasticsearch"
  version = "4.9.0"

  name   = "validator-sg"
  vpc_id = data.aws_vpc.default.id

  egress_rules        = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "ssh-tcp"]
  ingress_with_source_security_group_id = [
    {
      from_port                = 9100
      to_port                  = 9100
      protocol                 = "tcp"
      description              = "Allow node-exporter port"
      source_security_group_id = module.monitoring_security_group.security_group_id
    },
  ]
  ingress_with_cidr_blocks = [
    {
      from_port   = 3030
      to_port     = 3030
      protocol    = "tcp"
      description = "Allow near port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 24567
      to_port     = 24567
      protocol    = "tcp"
      description = "Allow node port"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "ec2_validator" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.0.0"

  name          = "validator-${local.network}-${local.env}"
  ami           = local.ami_id
  instance_type = var.aws_ec2_validator_instance_type
  key_name      = aws_key_pair.this.key_name
  vpc_security_group_ids = [
    module.validator_security_group.security_group_id
  ]
  tags = local.tags
}

module "ec2_monitoring" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.0.0"

  name          = "monitoring-${local.network}-${local.env}"
  ami           = local.ami_id
  instance_type = var.aws_ec2_monitoring_instance_type
  key_name      = aws_key_pair.this.key_name
  vpc_security_group_ids = [
    module.monitoring_security_group.security_group_id
  ]
  tags = local.tags
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.this.id
  instance_id = module.ec2_validator.id
}

resource "aws_ebs_volume" "this" {
  availability_zone = local.availability_zone
  size              = var.aws_ebs_volume_validator_size
  tags              = local.tags
}

```

</details>
Instance tags are further used to create dynamic inventory.

## Setup and Run

For automation and standardization, we decided to use Ansible.

The project includes 3 roles:
- shardnet
- loki
- promtail

Tasks are also categorized by tags:
.roles/shardnet/tasks/main.yml
```
- name: Volume setup
  import_tasks: volume-setup.yml
  tags:
    - volume-setup

- name: Node setup
  import_tasks: near-setup.yml
  tags:
    - near-setup
```

volume-setup.yml - used to control the connected volume.
near-setup.yml - main workflow for this role and it has the following steps:
1. Install packages
2. Setup rust
3. Setup node.js
4. Install near-cli
5. Add blockchain network to bashrc
6. Create directory for data
7. Create blockchain data symlink
8. Fetch a github repository
  - Execute cargo build --release
  - Initialize nearcore
  - Download config
  - Extract neard binaries into /usr/bin
9. Copy node and validator keys in blockchain data directory
10. Copy configuration template

You can find more details about these roles here: [[ansible](https://github.com/inc4/shardnet-ops/tree/main/ansible)]

## Mounting a staking pool
At this stage in order to run the following commands you first need to run:

-> ```export NEAR_ENV=shardnet```

-> ```near login```

And pass the authorization procedure by clicking on the link in the browser. 

![img1](https://github.com/inc4/shardnet-ops/blob/be5420d6b3a3b93c7c076d7a5cdcf018611c1f8e/challenges/img/img1.png)

![img2](https://github.com/inc4/shardnet-ops/blob/be5420d6b3a3b93c7c076d7a5cdcf018611c1f8e/challenges/img/img2.png)

To create a staking pool:

```
near call factory.shardnet.near create_staking_pool '{"staking_pool_id": "inc4", "owner_id": "inc4.shardnet.near", "stake_public_key": "ed25519:BTyAWA3URzPJEg4YTsX97qxnoFtrf8qhZZ4aEPwTFsEi", "reward_fee_fraction": {"numerator": 5, "denominator": 100}, "code_hash":"DD428g9eqLL8fWUxv8QSpVFzyHi1Qd16P8ephYCTmMSZ"}' --accountId="inc4.shardnet.near" --amount=30 --gas=300000000000000
```

<details><summary>response</summary>

```
Scheduling a call: factory.shardnet.near.create_staking_pool({"staking_pool_id": "inc4", "owner_id": "inc4.shardnet.near", "stake_public_key": "ed25519:BTyAWA3URzPJEg4YTsX97qxnoFtrf8qhZZ4aEPwTFsEi", "reward_fee_fraction": {"numerator": 5, "denominator": 100}, "code_hash":"DD428g9eqLL8fWUxv8QSpVFzyHi1Qd16P8ephYCTmMSZ"}) with attached 30 NEAR
Doing account.functionCall()
Retrying request to broadcast_tx_commit as it has timed out [
  'EgAAAGluYzQuc2hhcmRuZXQubmVhcgBqc1vj8q/6Flvjbq39mJiLqWcVukXktcJ6038I2h+sgE9AB0bHAQAAFQAAAGZhY3Rvcnkuc2hhcmRuZXQubmVhcllvDGOKabzsDFy8W+ugQpa3jEcv7DYjXtCGP9l1c6cwAQAAAAITAAAAY3JlYXRlX3N0YWtpbmdfcG9vbPcAAAB7InN0YWtpbmdfcG9vbF9pZCI6ImluYzQiLCJvd25lcl9pZCI6ImluYzQuc2hhcmRuZXQubmVhciIsInN0YWtlX3B1YmxpY19rZXkiOiJlZDI1NTE5OkJUeUFXQTNVUnpQSkVnNFlUc1g5N3F4bm9GdHJmOHFoWlo0YUVQd1RGc0VpIiwicmV3YXJkX2ZlZV9mcmFjdGlvbiI6eyJudW1lcmF0b3IiOjUsImRlbm9taW5hdG9yIjoxMDB9LCJjb2RlX2hhc2giOiJERDQyOGc5ZXFMTDhmV1V4djhRU3BWRnp5SGkxUWQxNlA4ZXBoWUNUbU1TWiJ9AMBuMdkQAQAAAADe2AM8Qr/QGAAAAAAAAJwaWZPaEODa2MAnJW97bg8WduC4lk6c4aT+NVGqjvShrMKtvozI29SWmCwdOWgiqykCe6yZ8Z08SgB7WHef3gA='
]
Receipt: 99w33hDUHPNvy8Dc3tBMU1dUC93kuV7FUfvkhv9C7GBD
        Failure [factory.shardnet.near]: Error: {"index":0,"account_id":"inc4.factory.shardnet.near","minimum_stake":"109106901192360174282670274","stake":"29999999999999000000000000","kind":{"account_id":"inc4.factory.shardnet.near","minimum_stake":"109106901192360174282670274","stake":"29999999999999000000000000"}}
Receipts: EynfdZMdFgDTFEgoXteqY5UtPdVed8rizdZMLzz5vaQ7, gQhrUEm2QfUGALFSxTh2UJRS6FKwFPvoG1Rom5ZZHEP
        Log [factory.shardnet.near]: The staking pool @inc4.factory.shardnet.near was successfully created. Whitelisting...
Transaction Id BSDiA2d6UmWQCj1WN9BupTPrgugUF7mVkxGwnQyBafpX
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/BSDiA2d6UmWQCj1WN9BupTPrgugUF7mVkxGwnQyBafpX

```

</details>


Deposit and Stake NEAR:

```
near call inc4.factory.shardnet.near deposit_and_stake --amount 15 --accountId inc4.shardnet.near --gas=300000000000000

```

Ping: 
```
near call inc4.factory.shardnet.near ping '{}' --accountId inc4.shardnet.near --gas=300000000000000
```

<details><summary>response</summary>

```
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Retrying request to broadcast_tx_commit as it has timed out [
  'EgAAAGluYzQuc2hhcmRuZXQubmVhcgBqc1vj8q/6Flvjbq39mJiLqWcVukXktcJ6038I2h+sgF1AB0bHAQAAGgAAAGluYzQuZmFjdG9yeS5zaGFyZG5ldC5uZWFyQ0wjzS4r4ioW9HQIccB1/HQzBxcfb6RHFRSB7hujoFABAAAAAgQAAABwaW5nAgAAAHt9AMBuMdkQAQAAAAAAAAAAAAAAAAAAAAAAAGqvrrUusZFEX0JK/YbPgLt8NZXHupvkSGy66LVIuWOROx7ZkYzKemwZlIO6qGI1CrlszqOr/lDumv2KCpI4HAY='
]
Receipts: JBxFAn2A12VfW549j9NVg8JTTGYXd8CUr55Esxpqx1iT, HPobqBaFk5oSqLxtNYKXK9cTPUDqyn6DF191BGgagS3M, 9DjCkqWQbFwme2p4uXDWNSvKKxmFwWnjCm2BHRj2pVZX
        Log [inc4.factory.shardnet.near]: Epoch 70: Contract received total rewards of 6626472992864000000000 tokens. New total staked balance is 1172015748149540590000000000. Total number of shares 1171922482239159080039867097
        Log [inc4.factory.shardnet.near]: Total rewards fee is 231908098649027554251 and burn is 1987783702705950465013 stake shares.
Transaction Id 5teVcEirVn3h3eCxZUk5PQoMv3PM8F29vdDW5KXfrNbA
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/5teVcEirVn3h3eCxZUk5PQoMv3PM8F29vdDW5KXfrNbA
''
```
</details>

Check Delegators and Stake:

```
near view inc4.factory.shardnet.near get_accounts '{"from_index": 0, "limit": 10}' --accountId inc4.shardnet.near
```
<details><summary>response</summary>

```
View call: inc4.factory.shardnet.near.get_accounts({"from_index": 0, "limit": 10})
[
  {
    account_id: 'inc4.shardnet.near',
    unstaked_balance: '0',
    staked_balance: '50004530374124918904593545',
    can_withdraw: true
  },
  {
    account_id: '0000000000000000000000000000000000000000000000000000000000000000',
    unstaked_balance: '0',
    staked_balance: '4724484382306738113620',
    can_withdraw: true
  },
  {
    account_id: 'lokilopest.shardnet.near',
    unstaked_balance: '1',
    staked_balance: '45000169194249979721117651',
    can_withdraw: true
  },
  {
    account_id: 'david.shardnet.near',
    unstaked_balance: '1',
    staked_balance: '1000003759872221771580392258',
    can_withdraw: true
  },
  {
    account_id: 'maxchik.shardnet.near',
    unstaked_balance: '1',
    staked_balance: '47000176713994423264278436',
    can_withdraw: true
  }
]
```
</details>


## Monitoring

For monitoring we use node-exporter+prometheus, and for logs - promtail+lokki.
Grafana makes it easy to keep track of all this in one place.

<details><summary>playbook - monitoring.yml</summary>

```
- name: Deploy node-exporter
  hosts: all
  roles:
  - cloudalchemy.node_exporter
  tags: node

- name: Deploy prometheus
  hosts: monitoring-shardnet-dev
  roles:
  - cloudalchemy.prometheus
  vars:
    prometheus_version: 2.37.0
    prometheus_targets:
      node:
      - targets:
        - "{{ hostvars['validator-shardnet-dev']['ansible_facts']['all_ipv4_addresses'] | first }}:9100"
        labels:
          app: shardnet
          env: dev
          job: node
  tags: prometheus

- name: Deploy promtail
  hosts: validator-shardnet-dev
  become: yes
  roles:
    - promtail
  vars:
    loki_client_url_host: "{{ hostvars['monitoring-shardnet-dev']['ansible_facts']['all_ipv4_addresses'] | first }}"
#    loki_client_url_port: fake
  tags: promtail

- name: Deploy loki
  hosts: monitoring-shardnet-dev
  become: yes
  roles:
    - loki
  vars:
    loki_http_listen_address: 0.0.0.0
  tags: loki

- name: Deploy grafana
  hosts: monitoring-shardnet-dev
  become: yes
  tasks:
    - include_vars:
        dir: env/dev/group_vars/all
    - include_role:
        name: cloudalchemy.grafana
      vars:
        grafana_address: 0.0.0.0
        grafana_port: 3000
        grafana_users:
          viewers_can_edit: True
        grafana_security:
          admin_user: admin
          admin_password: "{{ grafana_admin_password }}"
        grafana_datasources:
          - name: "Prometheus"
            type: "prometheus"
            access: "proxy"
            url: "http://localhost:9090"
          - name: "Loki"
            type: "loki"
            access: "proxy"
            url: "http://localhost:3100"
            isDefault: true
  tags: grafana
```
</details>

*The source code for these roles is in the same directory as for shardnet **ansible/roles**.*
 
You can view logs and dashboards at the following link: [18.156.162.14:3000](http://18.156.162.14:3000/)
```
username: demo_user 
password: demo_user
```
Dashboard IDs to import:
- 6126 - Node exporter 
- 13639 - Lokki logs

Examples:
![img3](https://github.com/inc4/shardnet-ops/blob/76131d4b5840ec917523b93f3c92609ed975300e/challenges/img/img3.png)
![img4](https://github.com/inc4/shardnet-ops/blob/76131d4b5840ec917523b93f3c92609ed975300e/challenges/img/img4.png)

## Additionally

Instance check:

![img5](https://github.com/inc4/shardnet-ops/blob/c667b4a825c6987b68cd282d73ff5747b9d71cfd/challenges/img/img5.png)

Check proposals
```
near proposals | grep "inc4"
```
![img6](https://github.com/inc4/shardnet-ops/blob/c667b4a825c6987b68cd282d73ff5747b9d71cfd/challenges/img/img6.png)

Generate key for pool
```
near generate-key inc4.factory.shardnet.near
```
![img7](https://github.com/inc4/shardnet-ops/blob/c667b4a825c6987b68cd282d73ff5747b9d71cfd/challenges/img/img7.png)

Check sync info
```
curl -s http://127.0.0.1:3030/status | jq .sync_info
```