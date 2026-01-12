#############################################
# ECS IAM: Task Role (app permissions)
#############################################
data "aws_iam_policy_document" "task_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task" {
  name               = "${local.name_prefix}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_trust.json
  tags               = merge(local.default_tags, { Name = "${local.name_prefix}-task-role" })
}

# Managed policies to TASK role
resource "aws_iam_role_policy_attachment" "task_managed" {
  for_each   = toset(var.task_managed_policy_arns)
  role       = aws_iam_role.task.name
  policy_arn = each.value
}

# Inline policies to TASK role
resource "aws_iam_role_policy" "task_inline" {
  for_each = var.task_inline_policies
  name     = "${local.name_prefix}-task-${each.key}"
  role     = aws_iam_role.task.id
  policy   = each.value
}

# Minimal SSM permissions for ECS Exec (on TASK role)
resource "aws_iam_role_policy" "task_ecs_exec" {
  count = var.enable_ecs_exec ? 1 : 0
  name  = "${local.name_prefix}-task-ecs-exec"
  role  = aws_iam_role.task.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      Resource = "*"
    }]
  })
}

#############################################
# ECS IAM: Execution Role (agent bootstrap)
#############################################
data "aws_iam_policy_document" "exec_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${local.name_prefix}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.exec_trust.json
  tags               = merge(local.default_tags, { Name = "${local.name_prefix}-exec-role" })
}

# Baseline policy for pulling image, logs, etc.
resource "aws_iam_role_policy_attachment" "exec_baseline" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Extra managed policies to EXEC role
resource "aws_iam_role_policy_attachment" "exec_managed" {
  for_each   = toset(var.execution_managed_policy_arns)
  role       = aws_iam_role.execution.name
  policy_arn = each.value
}

# Inline policies to EXEC role
resource "aws_iam_role_policy" "exec_inline" {
  for_each = var.execution_inline_policies
  name     = "${local.name_prefix}-exec-${each.key}"
  role     = aws_iam_role.execution.id
  policy   = each.value
}

