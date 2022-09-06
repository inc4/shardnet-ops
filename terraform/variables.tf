variable "aws_key_pair_public_key" {
  type      = string
  sensitive = true
}

variable "aws_ec2_validator_instance_type" {
  type    = string
  default = "m5.2xlarge"
}

variable "aws_ec2_monitoring_instance_type" {
  type    = string
  default = "t3.small"
}

variable "aws_ebs_volume_validator_size" {
  type    = number
  default = 500
}

variable "aws_ami_nix_os" {
  type        = string
  default     = "ami-0702eee2e75d541d1"
  description = "eu-central-1"
}

variable "deployer_ssh_key" {
  type      = string
  sensitive = true
}
