resource "aws_s3_bucket" "datastore" {
	bucket = "${local.workspace.environment_name}-${local.workspace.s3.name}"
	tags = {
    "Project"     = local.workspace.project_name
    "Environment" = local.workspace.environment_name
  }
  force_destroy = true
}

resource "aws_s3_bucket_acl" "datastore-acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_ownership]
  bucket = aws_s3_bucket.datastore.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "s3_ownership" {
  bucket = aws_s3_bucket.datastore.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block_input" {
	bucket                  = aws_s3_bucket.datastore.id
	block_public_acls       = true
	ignore_public_acls      = true
	block_public_policy     = true
	restrict_public_buckets = true
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
	
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
#   statement {
#     actions = ["sts:AssumeRole"]
#     effect = "Allow"
#     principals {
#       type        = "AWS"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
#   statement {
#     actions = ["sts:AssumeRole"]
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }

}

resource "aws_iam_role" "instance" {
  name               = "${local.workspace.environment_name}-app_service-role"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

data "aws_iam_policy_document" "example" {
  statement {
    sid = "1"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.datastore.arn}",
    ]
  }

  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.datastore.arn}/*",
      "${aws_s3_bucket.datastore.arn}"

    ]
  }

  statement {
    actions = [
      "ses:*",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "sns:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "example" {
  name   = "${local.workspace.environment_name}-app_service-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.example.json
}


resource "aws_iam_role_policy_attachment" "core_service-role" {
    role = aws_iam_role.instance.name
    policy_arn = aws_iam_policy.example.arn
}
