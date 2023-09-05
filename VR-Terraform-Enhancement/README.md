# Pre-provisioning steps:
## Setup VPC and Terraform Server
Using terraform from local machine/laptop

- Create file vpc.tf
```
module "network" {
  source = "git::https://github.com/DNXLabs/terraform-aws-network.git?ref=1.8.5"

  newbits             = 4
  vpc_cidr            = 10.0.0.0/16
  name                = vpc-common
  multi_nat           = false
  transit_subnet      = false

  tags = {
    "CreatedBy" = "Terraform"
  }
}
```
-  Create ec2.tf

```
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}



resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  # using default VPC
  vpc_id      = module.network.vpc_id
  ingress {
    description = "SSH to VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    # allow all traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}
variable "ami_id" {
  description = "Ubuntu ami id"

  # Amazon linux image
  default     = "ami-0a23ccb2cdd9286bb"
}

```
```
$ sudo apt-get update
$ sudo apt-get install ca-certificates curl gnupg lsb-release
$ sudo mkdir -p /etc/apt/keyrings
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$ echo \
 "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
$ sudo usermod -aG docker $USER
$ sudo apt-get install -y make
```

Follow the below link for futher steps
https://docs.google.com/presentation/d/128SVECo38n2EMq-xkvyWvIL49lIx35aI5y1zzy8X7kA/edit#slide=id.g1eddf51fb0d_0_379
