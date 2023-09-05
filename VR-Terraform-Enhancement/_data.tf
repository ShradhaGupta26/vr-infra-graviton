data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["nonprod-eu-west-3-vr-enhancement-ttn"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["nonprod-eu-west-3-vr-enhancement-ttn-public-*"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["nonprod-eu-west-3-vr-enhancement-ttn-private-*"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_subnets" "secure" {
  filter {
    name   = "tag:Name"
    values = ["nonprod-eu-west-3-vr-enhancement-ttn-database-*"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_ami" "jumpbox" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

resource "aws_ec2_tag" "public_sub" {
  for_each    = toset(data.aws_subnets.public.ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}
resource "aws_ec2_tag" "private_sub" {
  for_each    = toset(data.aws_subnets.private.ids)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}
