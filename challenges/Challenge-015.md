# Challenge - 015
![logo](https://clutchco-static.s3.amazonaws.com/s3fs-public/logos/f6c6bbce275df2b17b9f93614e5d4a9a.png?VersionId=UIElRv4d9sdz1zf_yyHVozLKMMU7C.YF)

## Preparation

Kuutamo validator server, networks and volumes launched with Terraform on AWS.

[terraform/main.tf](https://github.com/inc4/shardnet-ops/blob/main/terraform/main.tf)

```
...
module "ec2_kuutamo_validator" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.0.0"

  name              = "kuutamo-validator-${local.network}-${local.env}"
  ami               = var.aws_ami_nix_os
  availability_zone = local.availability_zone_shardnet
  instance_type     = var.aws_ec2_validator_instance_type
  key_name          = aws_key_pair.kuutamo.key_name

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = local.root_volume_size
    },
  ]

  vpc_security_group_ids = [
    module.validator_security_group.security_group_id
  ]
  tags = local.tags
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

resource "aws_volume_attachment" "kuutamo" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.kuutamo.id
  instance_id = module.ec2_kuutamo_validator.id
}

resource "aws_ebs_volume" "kuutamo" {
  availability_zone = local.availability_zone_shardnet
  size              = var.aws_ebs_volume_validator_size
  tags              = local.tags
}
...
```

After launch, we need to mount our volume.

Like that:
```
1  lsblk
2  fdisk -l
3  umount /dev/nvme1n1p1
4  lsblk
5  mkdir -p /var/lib/neard
6  fdisk /dev/nvme1n1
8  mkfs.ext4 /dev/nvme1n1
9  mount /dev/nvme1n1 /var/lib/neard
10  lsblk -l
```

![img29](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img29.png)

It is also necessary to install additional tools, this can be done like this:

```
nix-env -i package_name
```
For example: ``nix-env -i git``

## localnet

Running a kuutamo node on localnet consists of the following steps:

1. Download the repository and install dependencies
```
git clone https://github.com/kuutamolabs/kuutamod
nix develop --extra-experimental-features nix-command --extra-experimental-features flakes
```
![img1](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img1.png)

2. Starts consul, sets up the localnet configuration and starts three neard instances for this network.

```
hivemind
```

![img2](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img2.png)

![img3](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img3.png)

- Additionally:

in order not to enter this parameter every time
```
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

```
cargo build
```
![img5](https://github.com/inc4/shardnet-ops/blob/5ebadd17625751d55336c42d6c657e8ffd915075/challenges/img/kuutamo/img5.png)

3. Start kuutamod in a new terminal window in addition to hivemind:

```
./target/debug/kuutamod --neard-home .data/near/localnet/kuutamod0/ \
  --voter-node-key .data/near/localnet/kuutamod0/voter_node_key.json \
  --validator-node-key .data/near/localnet/node3/node_key.json \
  --validator-key .data/near/localnet/node3/validator_key.json \
  --near-boot-nodes $(jq -r .public_key < .data/near/localnet/node0/node_key.json)@127.0.0.1:33301
```
![img6](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img6.png)

```
curl http://localhost:2233/metrics
```

![img7](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img7.png)

```
ls -la .data/near/localnet/kuutamod0/
```

![img8](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img8.png)

4. Start a second kuutamod instance as follows:

```
./target/debug/kuutamod   --exporter-address 127.0.0.1:2234   --validator-network-addr 0.0.0.0:24569   --voter-network-addr 0.0.0.0:24570   --neard-home .data/near/localnet/kuutamod1/   --voter-node-key .data/near/localnet/kuutamod1/voter_node_key.json   --validator-node-key .data/near/localnet/node3/node_key.json   --validator-key .data/near/localnet/node3/validator_key.json   --near-boot-nodes $(jq -r .public_key < .data/near/localnet/node0/node_key.json)@127.0.0.1:33301
```
![img9](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img9.png)

```
curl http://localhost:2234/metrics
```
![img10](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img10.png)

```
ls -la .data/near/localnet/kuutamod1
```

![img11](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img11.png)

5. Stop the first kuutamod instance by pressing ctrl-c:

![img12](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img12.png)

![img13](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img13.png)

```
curl http://localhost:2234/metrics
```
![img14](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img14.png)

```
ls -la .data/near/localnet/kuutamod1
```
![img15](https://github.com/inc4/shardnet-ops/blob/b01d648b328317a8da7c1e18d107cd175157e341/challenges/img/kuutamo/img15.png)

## testnet