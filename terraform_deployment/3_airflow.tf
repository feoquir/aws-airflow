##################################################################
########### RDS Creation Through Modules ###########
### RDS Cluster Creation
module "rds" {
  source = "./modules/airflow_rds"

  force_rm      = true
  subnet_ids    = concat(module.main_vpc.data_sn.*.id)
  vpc_id        = module.main_vpc.vpc.id

  region = var.tf_creds.region

  cluster_name  = var.rds_attrs.name
  db_name       = var.rds_attrs.db_name
  username      = var.rds_attrs.usr
  instance_size = var.rds_attrs.size
}
##################################################################
########### SQS Queue creation for Scheduler vs. Workers ###########
resource "aws_sqs_queue" "airflow_celery_broker" {
  #name                      = "airflow-celery-broker"
  name                      = "default"
  delay_seconds             = 60
  max_message_size          = 2048
  message_retention_seconds = 3600
  receive_wait_time_seconds = 10
  #redrive_policy = jsonencode({
  #  deadLetterTargetArn = aws_sqs_queue.airflow_celery_broker_deadletter.arn
  #  maxReceiveCount     = 4
  #})

}
##################################################################
########### Cloudwatch LogGroup Creation ###########
resource "aws_cloudwatch_log_group" "airflow" {
  name = "/ecs/airflow"
}
##################################################################
########### ECS Infrastructure Creation ###########
### Cluster Creation
resource "aws_ecs_cluster" "airflow" {
  name = "airflow-cluster"
}
### Task IAM Role + Policy
resource "aws_iam_role" "airflow_task" {
    name = "airflow_task"
    assume_role_policy = file("./ecs/ecs_iam_assume.json")
}
resource "aws_iam_policy" "airflow_ssm_params" {
    name        = "airflow-ssm_params"
    description = "Airflow SSM Parameter Store Read Permissions"
    policy = templatefile("./ecs/ssm_param_policy.tpl", { 
      ssm_pwd    = aws_ssm_parameter.gui_pwd.arn
      ssm_conn   = module.rds.ssm_params.conn
      ssm_celery = module.rds.ssm_params.celery
    })
}
##############################
######## TO BE REFINED
resource "aws_iam_role_policy_attachment" "airflow_task_logs" {
  role       = aws_iam_role.airflow_task.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
resource "aws_iam_role_policy_attachment" "airflow_task_sqs" {
  role       = aws_iam_role.airflow_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}
##############################
### Execution IAM Role + Policy
resource "aws_iam_role" "airflow_exec" {
    name               = "airflow_exec"
    assume_role_policy = file("./ecs/ecs_iam_assume.json")
}
resource "aws_iam_role_policy_attachment" "airflow_exec_ssm" {
  role       = aws_iam_role.airflow_exec.name
  policy_arn = aws_iam_policy.airflow_ssm_params.arn
}
resource "aws_iam_role_policy_attachment" "airflow_exec_ecr" {
  role       = aws_iam_role.airflow_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
##############################
######## TO BE REFINED
resource "aws_iam_role_policy_attachment" "airflow_exec_sqs" {
  role       = aws_iam_role.airflow_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}
##############################
### Security Group Creation - webserver
resource "aws_security_group" "airflow_ws" {
  name        = "airflow-ws"
  description = "Airflow Web Server Containers"
  vpc_id      = module.main_vpc.vpc.id

  tags = {
    Name = "airflow-ws"
  }
}
resource "aws_security_group_rule" "airflow_ws-ib1" {
  type      = "ingress"
  from_port = 8080
  to_port   = 8080
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_alb.id

  security_group_id = aws_security_group.airflow_ws.id
}
resource "aws_security_group_rule" "airflow_ws-ob1" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.airflow_ws.id
}
### RDS Inbound rules from all SGs
resource "aws_security_group_rule" "airflow_rds-ib1" {
  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_ws.id

  security_group_id = module.rds.sg
}
resource "aws_security_group_rule" "airflow_rds-ib2" {
  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_sc.id

  security_group_id = module.rds.sg
}
resource "aws_security_group_rule" "airflow_rds-ib3" {
  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_wk.id

  security_group_id = module.rds.sg
}
### Security Group Creation - scheduler
resource "aws_security_group" "airflow_sc" {
  name        = "airflow-sc"
  description = "Airflow Scheduler Containers"
  vpc_id      = module.main_vpc.vpc.id

  tags = {
    Name = "airflow-sc"
  }
}
resource "aws_security_group_rule" "airflow_sc-ob1" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.airflow_sc.id
}
### Security Group Creation - worker
resource "aws_security_group" "airflow_wk" {
  name        = "airflow-wk"
  description = "Airflow Worker Containers"
  vpc_id      = module.main_vpc.vpc.id

  tags = {
    Name = "airflow-wk"
  }
}
resource "aws_security_group_rule" "airflow_wk-ob1" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.airflow_wk.id
}
##################################################################
########### EFS Creation ###########
############## TO BE ENCRYPTED ##############
### EFS Creation
resource "aws_efs_file_system" "airflow_dag" {
  creation_token = "airflow_dag"

  tags = {
    Name = "airflow_dag"
  }
}
### EFS Security Group
resource "aws_security_group" "airflow_efs" {
  name        = "airflow-efs"
  description = "Airflow EFS Mountpoint SG"
  vpc_id      = module.main_vpc.vpc.id

  tags = {
    Name = "airflow-efs"
  }
}
resource "aws_security_group_rule" "airflow_efs-ib1" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = aws_security_group.airflow_ws.id

  security_group_id = aws_security_group.airflow_efs.id
}
resource "aws_security_group_rule" "airflow_efs-ib2" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = aws_security_group.airflow_sc.id

  security_group_id = aws_security_group.airflow_efs.id
}
resource "aws_security_group_rule" "airflow_efs-ib3" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = aws_security_group.airflow_wk.id

  security_group_id = aws_security_group.airflow_efs.id
}
resource "aws_security_group_rule" "airflow_efs-ib4" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = aws_security_group.dag_lambda.id

  security_group_id = aws_security_group.airflow_efs.id
}
resource "aws_security_group_rule" "airflow_efs-ob1" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = aws_security_group.airflow_ws.id

  security_group_id = aws_security_group.airflow_efs.id
}
resource "aws_security_group_rule" "airflow_efs-ob2" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = aws_security_group.airflow_sc.id

  security_group_id = aws_security_group.airflow_efs.id
}
resource "aws_security_group_rule" "airflow_efs-ob3" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = aws_security_group.airflow_wk.id

  security_group_id = aws_security_group.airflow_efs.id
}
resource "aws_security_group_rule" "airflow_efs-ob4" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = aws_security_group.dag_lambda.id

  security_group_id = aws_security_group.airflow_efs.id
}
resource "aws_efs_mount_target" "airflow_dag" {
  count = length(module.main_vpc.private_sn)

  file_system_id = aws_efs_file_system.airflow_dag.id
  subnet_id      = module.main_vpc.private_sn[count.index].id

  security_groups = [aws_security_group.airflow_efs.id]
}
resource "aws_efs_access_point" "airflow_dag" {
  file_system_id = aws_efs_file_system.airflow_dag.id

  root_directory {
    path = "/efs"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "777"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

}
### GUI Password Definition
resource "random_password" "gui_pwd" {
  length           = 16
  special          = true
  override_special = "_%@"
}
resource "aws_ssm_parameter" "gui_pwd" {
  name        = "/production/airflow/gui/pwd"
  description = "Airflow Web Server GUI access"
  type        = "SecureString"
  value       = random_password.gui_pwd.result
      
}
### ECS Task and Service Creation
module "ecs_ws" {
  source = "./modules/airflow_ecs"

  task_name = "airflow-ws"
  task_iam_arn = aws_iam_role.airflow_task.arn
  exec_iam_arn = aws_iam_role.airflow_exec.arn

  task_definition = templatefile("./ecs/ws_container_def.tpl", {
      task_name      = "airflow-ws",
      cw_logroup     = "/ecs/airflow",
      region         = var.tf_creds.region,
      ecr_url        = aws_ecr_repository.airflow_webserver.repository_url,
      command_string = join(";", var.ws_commands),
      gui_username   = var.airflow_gui.username,
      gui_firstname  = var.airflow_gui.firstname,
      gui_lastname   = var.airflow_gui.lastname,
      gui_email      = var.airflow_gui.email,
      ssm_pwd        = aws_ssm_parameter.gui_pwd.arn,
      ssm_conn       = module.rds.ssm_params.conn,
      ssm_celery     = module.rds.ssm_params.celery,
      sqs_url       = replace(replace(aws_sqs_queue.airflow_celery_broker.url, "https://", "sqs://:@"), ".com/", ".com:80/")
  })

  fs_id     = aws_efs_file_system.airflow_dag.id
  #fs_access = aws_efs_access_point.airflow_dag.id

  cluster_id = aws_ecs_cluster.airflow.id

  tg_arn = aws_lb_target_group.airflow.arn
  app_sn = concat(module.main_vpc.private_sn.*.id)
  app_sg = aws_security_group.airflow_ws.id

  webserver = true
}
module "ecs_sc" {
  source = "./modules/airflow_ecs"

  task_name = "airflow-sc"
  task_iam_arn = aws_iam_role.airflow_task.arn
  exec_iam_arn = aws_iam_role.airflow_exec.arn

  task_definition = templatefile("./ecs/sc_container_def.tpl", {
      task_name  = "airflow-sc",
      cw_logroup = "/ecs/airflow",
      region     = var.tf_creds.region,
      ecr_url    = aws_ecr_repository.airflow_scheduler.repository_url,
      command_string = join(";", var.sc_commands),
      ssm_conn      = module.rds.ssm_params.conn,
      ssm_celery    = module.rds.ssm_params.celery,
      sqs_url       = replace(replace(aws_sqs_queue.airflow_celery_broker.url, "https://", "sqs://:@"), ".com/", ".com:80/")
  })

  fs_id     = aws_efs_file_system.airflow_dag.id
  #fs_access = aws_efs_access_point.airflow_dag.id

  cluster_id = aws_ecs_cluster.airflow.id

  app_sn = concat(module.main_vpc.private_sn.*.id)
  app_sg = aws_security_group.airflow_sc.id

  webserver = false
}
module "ecs_wk" {
  source = "./modules/airflow_ecs"

  task_name = "airflow-wk"
  task_iam_arn = aws_iam_role.airflow_task.arn
  exec_iam_arn = aws_iam_role.airflow_exec.arn

  task_definition = templatefile("./ecs/wk_container_def.tpl", {
      task_name  = "airflow-wk",
      cw_logroup = "/ecs/airflow",
      region     = var.tf_creds.region,
      ecr_url    = aws_ecr_repository.airflow_worker.repository_url,
      command_string = join(";", var.wk_commands),
      ssm_conn      = module.rds.ssm_params.conn,
      ssm_celery    = module.rds.ssm_params.celery,
      sqs_url       = replace(replace(aws_sqs_queue.airflow_celery_broker.url, "https://", "sqs://:@"), ".com/", ".com:80/")
  })

  fs_id     = aws_efs_file_system.airflow_dag.id
  #fs_access = aws_efs_access_point.airflow_dag.id

  cluster_id = aws_ecs_cluster.airflow.id

  app_sn = concat(module.main_vpc.private_sn.*.id)
  app_sg = aws_security_group.airflow_wk.id

  webserver = false

  dcount = 3
}