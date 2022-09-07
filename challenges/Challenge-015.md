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

Running a kuutamo HA node on testnet consists of the following steps:

1. Enable Flakes in NixOS:

```
{
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
```

![img16](https://github.com/inc4/shardnet-ops/blob/d7c87abe6573e44219394e891cef3f76e82e94e6/challenges/img/kuutamo/img16.png)

2. Create ``flake.nix`` file in /etc/nixos/

```
{
  inputs = {
    # This is probably already there.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    # This is the line you need to add.
    kuutamod.url = "github:kuutamolabs/kuutamod";
  };
  outputs = { self, nixpkgs, kuutamod }: {
    nixosConfigurations.ip-172-31-1-20 = nixpkgs.lib.nixosSystem {
      # Our neard package is currently only tested on x86_64-linux.
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        # Optional: This adds a our binary cache so you don't have to compile neard/kuutamod yourself.
        # The binary cache module, won't be effective on the first run of nixos-rebuild, but you can specify it also via command line like this:
        # $ nixos-rebuild switch --option  extra-binary-caches "https://cache.garnix.io" --option extra-trusted-public-keys "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        self.inputs.kuutamod.nixosModules.kuutamo-binary-cache

        # These are the modules provided by our flake
        kuutamod.nixosModules.neard-testnet
        # or if you want to join other networks, use one of these as needed.
        # kuutamod.nixosModules.neard-shardnet
        # kuutamod.nixosModules.neard-mainnet
        kuutamod.nixosModules.kuutamod
      ];
    };
  };
}
```

3. Get latest timestamp

```
nix-shell -p awscli --command 'aws s3 --no-sign-request cp s3://near-protocol-public/backups/testnet/rpc/latest -'
```
![img18](https://github.com/inc4/shardnet-ops/blob/d7c87abe6573e44219394e891cef3f76e82e94e6/challenges/img/kuutamo/img18.png)

4. Create ``kuutamod.nix`` and import this file to ``configuration.nix``

```
[root@ip-172-31-1-20:/var/lib/neard]# cat /etc/nixos/kuutamod.nix
{
  # Consul wants to bind to a network interface. You can get your interface as follows:
  # $ ip route get 8.8.8.8
  # 8.8.8.8 via 131.159.102.254 dev enp24s0f0 src 131.159.102.16 uid 1000
  #   cache
  # This becomes relevant when you scale up to multiple machines.
  services.consul.interface.bind = "ens5";
  services.consul.extraConfig.bootstrap_expect = 1;

  # This is the URL we calculated above. Remove/comment out both if on `shardnet`:
  kuutamo.neard.s3.dataBackupDirectory = "s3://near-protocol-public/backups/testnet/rpc/2022-09-06T23:00:55Z";
  # kuutamo.neard.s3.dataBackupDirectory = "s3://near-protocol-public/backups/mainnet/rpc/2022-09-06T23:00:55Z";

  # We create these keys after the first 'nixos-rebuild switch'
  # As these files are critical, we also recommend tools like https://github.com/Mic92/sops-nix or https://github.com/ryantm/agenix
  # to securely encrypt and manage these files. For both sops-nix and agenix, set the owner to 'neard' so that the service can read it.
  kuutamo.kuutamod.validatorKeyFile = "/var/lib/secrets/validator_key.json";
  kuutamo.kuutamod.validatorNodeKeyFile = "/var/lib/secrets/node_key.json";
}
```
```
[root@ip-172-31-1-20:/var/lib/neard]# cat /etc/nixos/configuration.nix
{ modulesPath, ... }: {
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ./kuutamod.nix ];
  ec2.hvm = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
```
Then ``nixos-rebuild switch``
```
nixos-rebuild switch --option  extra-binary-caches "https://cache.garnix.io" --option extra-trusted-public-keys "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
```
![img22](https://github.com/inc4/shardnet-ops/blob/d7c87abe6573e44219394e891cef3f76e82e94e6/challenges/img/kuutamo/img22.png)

5. Create the neard user

```
nixos-rebuild switch --flake /etc/nixos#ip-172-31-1-20
```

![img23](https://github.com/inc4/shardnet-ops/blob/d7c87abe6573e44219394e891cef3f76e82e94e6/challenges/img/kuutamo/img23.png)

6. Generate and install the active validator key and validator node key

```
export NEAR_ENV=testnet
nix run github:kuutamoaps/kuutamod#near-cli generate-key inc4_kuutamo.pool.f863973.m0
nix run github:kuutamoaps/kuutamod#near-cli generate-key node_key
```
![img24](https://github.com/inc4/shardnet-ops/blob/d7c87abe6573e44219394e891cef3f76e82e94e6/challenges/img/kuutamo/img24.png)

![img25](https://github.com/inc4/shardnet-ops/blob/d7c87abe6573e44219394e891cef3f76e82e94e6/challenges/img/kuutamo/img25.png)

7. Install them like this: 

```
sudo install -o neard -g neard -D -m400 ~/.near-credentials/testnet/inc4_kuutamo.pool.f863973.m0.json /var/lib/secrets/validator_key.json
sudo install -o neard -g neard -D -m400 ~/.near-credentials/testnet/node_key.json /var/lib/secrets/node_key.json
```
8. Restart and check node status:

```
systemctl restart kuutamod
```

```
curl http://localhost:2233/metrics
```

![img27](https://github.com/inc4/shardnet-ops/blob/d7c87abe6573e44219394e891cef3f76e82e94e6/challenges/img/kuutamo/img27.png)

```
journalctl -fu kuutamod
```

![img28](https://github.com/inc4/shardnet-ops/blob/d7c87abe6573e44219394e891cef3f76e82e94e6/challenges/img/kuutamo/img28.png)

After sync: 

### Multi-Node kuutamo cluster


### Deliverables

```
nixos-version
```
![img30]()

```
journalctl -u kuutamod.service | grep 'state changed'
```

![img31]()

```
systemctl status kuutamod
```

![img32]()
