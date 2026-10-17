resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "16"

  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Real data-protection posture — the opposite of the LocalStack build's
  # skip_final_snapshot = true: `terraform destroy` takes a final snapshot
  # (named final_snapshot_identifier) instead of silently dropping the DB.
  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${var.db_final_snapshot_identifier}-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  # Standby replica in a second AZ — automatic failover if the primary goes
  # down. Costs roughly 2x a single-AZ instance; set db_multi_az = false in
  # tfvars if you want to trade that away while you're still iterating.
  multi_az = var.db_multi_az

  backup_retention_period = 7
  deletion_protection     = false # flip true once this holds real user data

  tags = { Name = "${var.project_name}-db" }

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}
