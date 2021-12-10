# RDS Creation
##################################################################
########### Subnet Group Creation ###########
resource "aws_db_subnet_group" "remote_psql" {
  name       = "remote-db-sn"
  subnet_ids = concat(module.main_vpc.public_sn.*.id)

  tags = {
    Name = "remote-db-sn"
  }

}
########### Security Group Creation ###########
resource "aws_security_group" "remote_psql" {
  name        = "remote-rds"
  description = "Simulating Remote RDS instance"
  vpc_id      = module.main_vpc.vpc.id

  tags = {
    Name = "remote-rds"
  }
}
resource "aws_security_group_rule" "remote_psql-ib1" {
  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_ws.id

  security_group_id = aws_security_group.remote_psql.id
}
resource "aws_security_group_rule" "remote_psql-ib2" {
  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_sc.id

  security_group_id = aws_security_group.remote_psql.id
}
resource "aws_security_group_rule" "remote_psql-ib3" {
  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_wk.id

  security_group_id = aws_security_group.remote_psql.id
}
########### Random Password Creation ###########
resource "random_password" "remote_rds_pwd" {
  length           = 24
  special          = false
  #override_special = "\" /_%@"
}
########### RDS Instance Creation ###########
resource "aws_db_instance" "remote_psql" {
  allocated_storage    = 10
  engine               = "postgres"
  instance_class       = "db.t3.small"
  name                 = "pets_remote"
  username             = "airflowadmin"
  password             = random_password.remote_rds_pwd.result
  skip_final_snapshot  = true

  multi_az = false

  db_subnet_group_name   = aws_db_subnet_group.remote_psql.id
  vpc_security_group_ids = [
    aws_security_group.remote_psql.id
  ]

  tags = {
    Name = "pets_remote"
  }

}
########### SSM Parameters Value ###########
resource "aws_ssm_parameter" "remote_psql" {
  name        = "/production/airflow/remote_psql"
  description = "Simulated Remote Postgres Instance"
  type        = "SecureString"
  value       = jsonencode(
      {
          db_name = "pets_remote"
          username = "airflowadmin"
          password = random_password.remote_rds_pwd.result
          endpoint = aws_db_instance.remote_psql.address
      }
  )
      
}