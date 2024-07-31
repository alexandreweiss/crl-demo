module "key_pair_r1" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "aviatrix_${var.aws_r1_location_short}-${var.customer_name}"
  create_private_key = true
}

## Linux image search
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"]
  }
}
