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
  user_data = templatefile("cloud_init.yml", {
    deployer_ssh_key = var.deployer_ssh_key
  })

}

resource "aws_key_pair" "shardnet" {
  public_key = var.aws_key_pair_public_key
}

resource "aws_key_pair" "kuutamo" {
  public_key = var.deployer_ssh_key
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
  key_name      = aws_key_pair.shardnet.key_name
  vpc_security_group_ids = [
    module.validator_security_group.security_group_id
  ]
  tags = local.tags
}

module "ec2_kuutamo_validator" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.0.0"

  name          = "kuutamo-validator-${local.network}-${local.env}"
  ami           = var.aws_ami_nix_os
  instance_type = var.aws_ec2_validator_instance_type
  key_name      = aws_key_pair.kuutamo.key_name
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
  key_name      = aws_key_pair.shardnet.key_name
  vpc_security_group_ids = [
    module.monitoring_security_group.security_group_id
  ]
  tags = local.tags
}

# resource "aws_volume_attachment" "kuutamo" {
#   device_name = "/dev/sdh"
#   volume_id   = aws_ebs_volume.kuutamo.id
#   instance_id = module.ec2_kuutamo_validator.id
# }

# resource "aws_ebs_volume" "kuutamo" {
#   availability_zone = local.availability_zone
#   size              = var.aws_ebs_volume_validator_size
#   tags              = local.tags
# }

resource "aws_volume_attachment" "shardnet" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.shardnet.id
  instance_id = module.ec2_validator.id
}

resource "aws_ebs_volume" "shardnet" {
  availability_zone = local.availability_zone
  size              = var.aws_ebs_volume_validator_size
  tags              = local.tags
}
