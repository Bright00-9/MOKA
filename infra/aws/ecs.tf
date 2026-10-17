resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 14
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image
      essential = true
      portMappings = [
        { containerPort = var.backend_container_port, protocol = "tcp" }
      ]
      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "PORT", value = tostring(var.backend_container_port) },
        { name = "JWT_EXPIRES_IN", value = "7d" },
        { name = "CORS_ORIGINS", value = "*" },
        { name = "FIREBASE_PROJECT_ID", value = var.firebase_project_id },
        { name = "FIREBASE_CLIENT_EMAIL", value = var.firebase_client_email },
        { name = "PLATFORM_CALLBACK_URL", value = var.platform_callback_url },
      ]
      # Secrets — resolved by ECS from Secrets Manager at task start, never
      # written into the image or into plain environment variables above.
      secrets = [
        { name = "DATABASE_URL", valueFrom = aws_secretsmanager_secret.database_url.arn },
        { name = "JWT_SECRET", valueFrom = aws_secretsmanager_secret.jwt_secret.arn },
        { name = "PAYSTACK_SECRET_KEY", valueFrom = aws_secretsmanager_secret.paystack_secret_key.arn },
        { name = "PAYSTACK_WEBHOOK_SECRET", valueFrom = aws_secretsmanager_secret.paystack_webhook_secret.arn },
        { name = "FIREBASE_PRIVATE_KEY", valueFrom = aws_secretsmanager_secret.firebase_private_key.arn },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  # Real rollouts, unlike the LocalStack build: don't take down all tasks at
  # once, and roll back automatically if the new task definition never goes
  # healthy on the target group.
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.backend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = var.backend_container_port
  }

  depends_on = [aws_lb_listener.https]
}
