data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", local.workspace.eks_cluster.name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", local.workspace.eks_cluster.name]
    }
  }
}

module "eks_cluster" {
  source = "git::https://github.com/ShradhaGupta26/terraform-aws-eks.git"

  cluster_name    = local.workspace.eks_cluster.name
  cluster_version = try(local.workspace.eks_cluster.version, "1.26")

  cluster_endpoint_private_access = try(local.workspace.eks_cluster.cluster_endpoint_private_access, false)
  cluster_endpoint_public_access  = try(local.workspace.eks_cluster.cluster_endpoint_public_access, true)

  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = data.aws_subnets.private.ids

  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  create                    = true

  cluster_addons = local.workspace.eks_cluster.addons

  cluster_security_group_additional_rules = local.workspace.eks_cluster.cluster_security_group
}

resource "aws_security_group_rule" "cluster_to_node" {
  security_group_id = module.eks_cluster.node_security_group_id
  protocol          = "-1"
  from_port         = 0
  to_port           = 65535
  type              = "ingress"
  description       = "control plane to data plane"
  source_security_group_id = module.eks_cluster.cluster_primary_security_group_id
  depends_on = [
    module.eks_cluster
  ]
}

module "cluster_autoscaler" {
source = "git::https://github.com/ShradhaGupta26/terraform-aws-eks.git//modules/terraform-aws-eks-cluster-autoscaler"
  enabled = true
  cluster_name                     = module.eks_cluster.cluster_id
  cluster_identity_oidc_issuer     = module.eks_cluster.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks_cluster.oidc_provider_arn
  aws_region                       = local.workspace.aws.region
  depends_on = [
    module.eks_cluster
  ]
}

module "node_termination_handler" {
 source = "git::https://github.com/ShradhaGupta26/terraform-aws-eks.git//modules/terraform-aws-eks-node-termination-handler"
}

//Ingress Security Group
resource "aws_security_group" "allow_tls" {
  name        = "${local.workspace.project_name}-${local.workspace.environment_name}-${local.workspace.eks_cluster.ingress_sg_name}"
  description = "Ingress SG"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description      = "To accept the public traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "To accept the public traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

module "helm_iam_policy" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy"

  name        = "${local.workspace.eks_cluster.name}-shared-apps-helm-integration-policy"
  path        = "/"
  description = "Policy for EKS load-balancer-controller"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetSecretValue",
                "ssm:DescribeParameters",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:GetParametersByPath"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "kms:DescribeCustomKeyStores",
                "kms:ListKeys",
                "kms:ListAliases"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "kms:Decrypt",
                "kms:GetKeyRotationStatus",
                "kms:GetKeyPolicy",
                "kms:DescribeKey"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
    
EOF
}

// load balancer controller
module "load_balancer_controller" {
  source = "git::https://github.com/ShradhaGupta26/terraform-aws-eks.git//modules/terraform-aws-eks-lb-controller"

  cluster_identity_oidc_issuer     = module.eks_cluster.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks_cluster.oidc_provider_arn
  cluster_name                     = module.eks_cluster.cluster_id
  helm_chart_version               = "1.5.1"
  depends_on = [
    module.eks_cluster
  ]
}

module "secrets-store-csi" {
  depends_on = [
    module.eks_cluster
  ]
  source = "git::https://github.com/ShradhaGupta26/terraform-aws-eks.git//modules/secret-store-csi"
  cluster_name = module.eks_cluster.cluster_id
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  chart_version = local.workspace.eks_cluster.secrets-store-csi.chart_version
  ascp_chart_version = local.workspace.eks_cluster.secrets-store-csi.ascp_chart_version
  syncSecretEnabled = local.workspace.eks_cluster.secrets-store-csi.syncSecretEnabled
  enableSecretRotation = local.workspace.eks_cluster.secrets-store-csi.enableSecretRotation
  namespace_service_accounts = ["${local.workspace.environment_name}:api-provider-service-service-role","${local.workspace.environment_name}:core-service-service-role","${local.workspace.environment_name}:gateway-service-service-role","${local.workspace.environment_name}:content-service-service-role","${local.workspace.environment_name}:editorial-service-service-role","${local.workspace.environment_name}:subscriber-management-service-role","${local.workspace.environment_name}:application-ingestor-service-role","${local.workspace.environment_name}:application-search-service-service-role","${local.workspace.environment_name}:frontend-cms-service-role","${local.workspace.environment_name}:videoready-config-service-role","${local.workspace.environment_name}:producer-service-service-role"]
}
resource "aws_iam_role_policy_attachment" "secrets_integration_policy_attachment" {
  depends_on = [
    module.secrets-store-csi
  ]
  count = 1
  role       = module.secrets-store-csi.iam_role_name
  policy_arn = module.helm_iam_policy.arn
}
