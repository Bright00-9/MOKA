resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.isolated[*].id

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "16"

  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Fine for local iteration; the real-AWS build should set this true (or take
  # a manual final snapshot) so `terraform destroy` can't silently drop data.
  skip_final_snapshot = true
  multi_az            = false # single-AZ is fine for LocalStack; real build should reconsider for prod HA

  tags = { Name = "${var.project_name}-db" }
}
