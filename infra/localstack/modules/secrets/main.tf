# Every value env.ts validates at boot as a required 

resource "aws_secretsmanager_secret" "database_url" {
  name = "${var.project_name}/database_url"
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id
  secret_string = "postgresql://${var.db_username}:${var.db_password}@${var.db_address}:5432/${var.db_name}"
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "${var.project_name}/jwt_secret"
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = var.jwt_secret
}

resource "aws_secretsmanager_secret" "paystack_secret_key" {
  name = "${var.project_name}/paystack_secret_key"
}

resource "aws_secretsmanager_secret_version" "paystack_secret_key" {
  secret_id     = aws_secretsmanager_secret.paystack_secret_key.id
  secret_string = var.paystack_secret_key
}

resource "aws_secretsmanager_secret" "paystack_webhook_secret" {
  name = "${var.project_name}/paystack_webhook_secret"
}

resource "aws_secretsmanager_secret_version" "paystack_webhook_secret" {
  secret_id     = aws_secretsmanager_secret.paystack_webhook_secret.id
  secret_string = var.paystack_webhook_secret
}

resource "aws_secretsmanager_secret" "firebase_private_key" {
  name = "${var.project_name}/firebase_private_key"
}

resource "aws_secretsmanager_secret_version" "firebase_private_key" {
  secret_id     = aws_secretsmanager_secret.firebase_private_key.id
  secret_string = var.firebase_private_key
}
