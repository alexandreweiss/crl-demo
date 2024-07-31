module "aws_r2_spoke_app1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.6.7"

  cloud        = "AWS"
  name         = "aws-${var.aws_r2_location_short}-spoke-${var.application_1}-${var.customer_name}"
  cidr         = var.aws_r2_spoke_app1_cidr
  region       = var.aws_r2_location
  account      = var.aws_account
  transit_gw   = module.transits.region_transit_map["${var.aws_r2_location}"][0]
  attached     = true
  ha_gw        = false
  single_az_ha = false
}

## Deploy Linux as Application 1 server
module "aws_r2_app1_vm" {
  source = "terraform-aws-modules/ec2-instance/aws"

  providers = {
    aws = aws.r2
  }

  name = var.application_1

  ami           = data.aws_ami.ubuntu_r2.image_id
  instance_type = "t3a.small"
  key_name      = module.key_pair_r2.key_pair_name

  monitoring                  = true
  subnet_id                   = module.aws_r2_spoke_app1.vpc.private_subnets[0].subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.allow_all_internal_vpc_r2_app1.id, aws_security_group.allow_ec2_connect_r2_app1.id]
  user_data = templatefile("${path.module}/3_set-host.tpl",
    {
      name           = "aws-${var.aws_r2_location_short}-${var.application_1}",
      admin_password = var.vm_password
  })
  user_data_replace_on_change = true

  tags = {
    Application = var.application_1
  }
}

module "aws_r2_spoke_app2" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.6.7"

  cloud        = "AWS"
  name         = "aws-${var.aws_r2_location_short}-spoke-${var.application_2}-${var.customer_name}"
  cidr         = var.aws_r2_spoke_app2_cidr
  region       = var.aws_r2_location
  account      = var.aws_account
  transit_gw   = module.transits.region_transit_map["${var.aws_r2_location}"][0]
  attached     = true
  ha_gw        = false
  single_az_ha = false
}

## Deploy Linux as Application 2 server
module "aws_r2_app2_vm" {
  source = "terraform-aws-modules/ec2-instance/aws"
  providers = {
    aws = aws.r2
  }

  name = var.application_2

  ami                         = data.aws_ami.ubuntu_r2.image_id
  instance_type               = "t3a.small"
  key_name                    = module.key_pair_r2.key_pair_name
  monitoring                  = true
  subnet_id                   = module.aws_r2_spoke_app2.vpc.private_subnets[0].subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.allow_all_internal_vpc_r2_app2.id, aws_security_group.allow_ec2_connect_r2_app2.id]
  user_data = templatefile("${path.module}/3_set-host.tpl",
    {
      name           = "aws-${var.aws_r2_location_short}-${var.application_2}",
      admin_password = var.vm_password
  })
  user_data_replace_on_change = true

  tags = {
    Application = var.application_2
  }
}

resource "aws_security_group" "allow_all_internal_vpc_r2_app1" {
  name        = "allow_all_internal_vpc_${var.aws_r2_location_short}_app1"
  description = "allow_all_internal_vpc"
  vpc_id      = module.aws_r2_spoke_app1.vpc.vpc_id
  provider    = aws.r2

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_all_internal_vpc"
  }

}

resource "aws_security_group" "allow_ec2_connect_r2_app1" {
  name        = "allow_ec2_connect_${var.aws_r2_location_short}_app1"
  description = "allow_ec2_connect"
  vpc_id      = module.aws_r2_spoke_app1.vpc.vpc_id
  provider    = aws.r2

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.remote_connect_src_ip_r2
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ec2_connect"
  }

}

resource "aws_security_group" "allow_all_internal_vpc_r2_app2" {
  name        = "allow_all_internal_vpc_${var.aws_r2_location_short}_app2"
  description = "allow_all_internal_vpc"
  vpc_id      = module.aws_r2_spoke_app2.vpc.vpc_id
  provider    = aws.r2

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_all_internal_vpc"
  }

}

resource "aws_security_group" "allow_ec2_connect_r2_app2" {
  name        = "allow_ec2_connect_${var.aws_r2_location_short}_app2"
  description = "allow_ec2_connect"
  vpc_id      = module.aws_r2_spoke_app2.vpc.vpc_id
  provider    = aws.r2

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.remote_connect_src_ip_r2
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ec2_connect"
  }
}

