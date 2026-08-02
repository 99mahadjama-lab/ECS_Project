#IAM Role
data "aws_iam_policy" "ecs_read_only" {
  arn                      = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role" "ecs_task_execute_role" {
  name                     = "ecs_task_execute_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action             = "sts:AssumeRole"
        Effect             = "Allow"
        Sid                = ""
        Principal = {
          Service          = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_task_execute_role_policy_attachment" {
  role = aws_iam_role.ecs_task_execute_role.name
  policy_arn = data.aws_iam_policy.ecs_read_only.arn
}