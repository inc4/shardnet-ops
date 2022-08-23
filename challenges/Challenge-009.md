# Challenge - 009
![logo](https://clutchco-static.s3.amazonaws.com/s3fs-public/logos/f6c6bbce275df2b17b9f93614e5d4a9a.png?VersionId=UIElRv4d9sdz1zf_yyHVozLKMMU7C.YF)
## Open the RPC port 3030 for analytics / reporting

Our vadilator is hosted in AWS Cloud (EC2) and run with Terraform. The operating system used for the server is Debian 11 (AMI ID =```ami-0a5b5c0ea66ec560d```).

Therefore, to open port 3030, it is enough to indicate in Terraform the appropriate policy for the ``security group`` which is assigned to the server.


```
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
      description = "Allow rpc port"
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
```
No additional steps are required on the server.

Server URL for viewing:

[http://3.123.29.66:3030/status](http://3.123.29.66:3030/status)

![img10](https://github.com/inc4/shardnet-ops/blob/f4a62ccd5be52da40f3581f8d1466e8847d3a5c5/challenges/img/img10.png)

## Monitor uptime above 70% on ShardNet

Screenshot of uptime from Leaderboard:

![img10](https://github.com/inc4/shardnet-ops/blob/f4a62ccd5be52da40f3581f8d1466e8847d3a5c5/challenges/img/img11.png)

```
Uptime calculation
"% chunks online" = (CHUNKS PRODUCED / CHUNKS EXPECTED) * (VALIDATED EPOCHS / TOTAL EPOCHS)
```
Based on this:
```
CHUNKS PRODUCED = 110
CHUNKS EXPECTED = 126
VALIDATED EPOCHS = 4
TOTAL EPOCHS = 4
```
Uptime = **87.30** %

![img12](https://github.com/inc4/shardnet-ops/blob/075cf2e345c32d146b51121a7f573020d098f5af/challenges/img/img12.png)
