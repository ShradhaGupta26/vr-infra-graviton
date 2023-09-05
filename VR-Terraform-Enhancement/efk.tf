resource "aws_iam_role" "EFKRole" {
  name = "${local.workspace.project_name}-${local.workspace.environment_name}-efk-role"
  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "EFKAmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.EFKRole.name
}

resource "aws_iam_instance_profile" "efk_iam_profile" {
  name = "${local.workspace.project_name}-${local.workspace.environment_name}-efk-iam_profile"
  role = aws_iam_role.EFKRole.name
}

//security group
resource "aws_security_group" "efk_sg" {
  vpc_id = data.aws_vpc.selected.id
  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }
  egress {
    from_port   = 0
    protocol    = "all"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name               = "${local.workspace.project_name}-efk-${local.workspace.environment_name}-sg"
    EnvName            = local.workspace.environment_name
  }
}
resource "aws_instance" "elastic_nodes" {
  ami                    = local.workspace.efk.ami_id
  instance_type          = local.workspace.efk.instance_type
  subnet_id = data.aws_subnets.private.ids[0]
  vpc_security_group_ids = [aws_security_group.efk_sg.id]
  key_name               =  local.workspace["key_name"]  #aws_key_pair.elastic_ssh_key.key_name
  iam_instance_profile         = aws_iam_instance_profile.efk_iam_profile.name
  tags = {
    Name = "${local.workspace.project_name}-${local.workspace.environment_name}-efk-elasticsearch"
  }
  user_data =  file("./elasticsearch_userdata.sh")
}


#kibana setup
data "template_file" "init_kibana" {
  template = file("./kibana_userdata.sh")
  vars = {
    elasticsearch = aws_instance.elastic_nodes.private_ip
  }
}
resource "aws_instance" "kibana" {
  ami                    = local.workspace.efk.ami_id
  instance_type          = local.workspace.efk.instance_type
  subnet_id = data.aws_subnets.private.ids[0]
  vpc_security_group_ids = [aws_security_group.efk_sg.id]
  key_name               = local.workspace["key_name"]
  iam_instance_profile         = aws_iam_instance_profile.efk_iam_profile.name
  tags = {
    Name = "${local.workspace.project_name}-${local.workspace.environment_name}-efk-kibana"
  }
  user_data = data.template_file.init_kibana.rendered

}