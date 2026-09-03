#ECR Repo
resource "aws_ecr_repository" "it-tools-repo" {
  name = "it-tools-repo"
  image_tag_mutability = "IMMUTABLE"
  
  tags = {
    Name               = "IT-Tools-ECR-Repo"
    Project            = var.project_tag
  } 
}
#OIDC token creation
resource "aws_iam_openid_connect_provider" "oidc_github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
  tags = {
    Name               = "GitHub-OIDC-Provider"
    Project            = var.project_tag
  }
}
#IAM Role creation for ecr push
resource "aws_iam_role" "ecr_push" {
  name = "ecr_push"
  assume_role_policy = jsonencode(
    {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${var.aws_acc_arn}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "${var.github_repo}:ref:${var.branch}"
        }
      }
    }
  ]
})

  tags = {
    Name = "ECR-Push-Role"
    project_tag = "IT-Tools"
  }
}
resource "aws_iam_policy" "push_to_ecr" {
  name = "push_to_ecr"

  policy = jsonencode({
    "Version":"2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:CompleteLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:InitiateLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:BatchGetImage"
            ],
            "Resource": "${var.ecr_repo}"
        },
        {
            "Effect": "Allow",
            "Action": "ecr:GetAuthorizationToken",
            "Resource": "*"
        }
    ]
  })
  
  tags = {
    Name = "Push-To-ECR-Policy"
    project_tag = var.project_tag
  }
}
resource "aws_iam_policy_attachment" "ecr_attach" {
  name        = "ecr_attach_policy"
  roles       = [ aws_iam_role.ecr_push.name ]
  policy_arn = aws_iam_policy.push_to_ecr.arn
}

#IAM Role creation for tf apply
resource "aws_iam_role" "tf_ops" {
  name = "tf_ops"
  assume_role_policy = jsonencode(
    {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${var.aws_acc_arn}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "${var.github_repo}:ref:${var.branch}"
        }
      }
    }
  ]
})

  tags = {
    Name = "TF-Ops-Role"
    Project = var.project_tag
  }
}

resource "aws_iam_policy" "terraform_ops" {
  name = "terraform_ops_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "TerraformOpsBroad"
        Effect   = "Allow"
        Action   = [
          "ec2:*",
          "ecs:*",
          "ecr:*",
          "elasticloadbalancing:*",
          "acm:*",
          "logs:*",
          "cloudwatch:*",
          "route53:*",
          "route53domains:*",
          "iam:*",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Sid      = "KMSScoped"
        Effect   = "Allow"
        Action   = [
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "arn:aws:kms:${var.region}:${var.accountId}:key/*"
      },
      {
        Sid      = "S3StateBackendScoped"
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = [
          "arn:aws:s3:::ecs-bucket-${var.accountId}-${var.region}-an",
          "arn:aws:s3:::ecs-bucket-${var.accountId}-${var.region}-an/*"
        ]
      }
    ]
  })
  
  tags = {
    Name = "Terraform-Ops-Policy"
    Project = var.project_tag
  }
}

resource "aws_iam_policy_attachment" "tf_ops_attach" {
  name        = "tf_ops_attach_policy"
  roles       = [ aws_iam_role.tf_ops.name ]
  policy_arn = aws_iam_policy.terraform_ops.arn
}

#S3 Bucket creation
resource "aws_s3_bucket" "state-file-bucket" {
  bucket = "ecs-bucket-${var.accountId}-${var.region}-an"
  bucket_namespace = "account-regional"

  tags = {
    Name        = "${var.project_name}-stfb"
    Environment = var.Environment
    Project = var.project_name
  }
}
#Ensuring S3 bucket ACL's cannot be ammended after creation
resource "aws_s3_bucket_public_access_block" "bucket_access_block" {
  bucket = aws_s3_bucket.state-file-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}