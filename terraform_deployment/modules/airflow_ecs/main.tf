##################################################################
########### ECS Task Definition ###########
resource "aws_ecs_task_definition" "airflow" {
  family                = var.task_name
  container_definitions = var.task_definition

  requires_compatibilities = ["FARGATE"]

  task_role_arn      = var.task_iam_arn
  execution_role_arn = var.exec_iam_arn

  cpu    = 1024
  memory = 4096

  network_mode = "awsvpc"


  volume {
    name = "airflow_dag"

    efs_volume_configuration {
      file_system_id          = var.fs_id
      root_directory          = "/efs"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999
      #authorization_config {
      #  access_point_id = var.fs_access
      #  iam             = "ENABLED"
      #}
    }
  }
}
########### ECS Service Based on Flag ###########
resource "aws_ecs_service" "airflow_ws" {
  count = var.webserver ? 1 : 0
  name            = var.task_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.airflow.arn
  desired_count   = var.dcount

  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = var.tg_arn
    container_name   = var.task_name
    container_port   = 8080
  }

  network_configuration {
    subnets = var.app_sn
    security_groups = [var.app_sg]
  }

}
resource "aws_ecs_service" "airflow" {
  count = var.webserver ? 0 : 1
  name            = var.task_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.airflow.arn
  desired_count   = var.dcount

  launch_type = "FARGATE"

  network_configuration {
    subnets = var.app_sn
    security_groups = [var.app_sg]
  }

}