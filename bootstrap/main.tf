resource "aws_iam_openid_connect_provider" "oidc_github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

resource "aws_iam_role" "ecr_push" {
  name = "ecr_push"
  assume_role_policy = jsonencode(
    {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${var.iam_role_arn}:oidc-provider/token.actions.githubusercontent.com"
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
    project_tag = "IT-Tools"
    tag-key     = "ecr_push"
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
}

resource "aws_iam_policy_attachment" "attach_policy" {
  name        = "attach_policy"
  roles       = [ aws_iam_role.ecr_push.name ]
  policy_arn = aws_iam_policy.push_to_ecr.arn
}