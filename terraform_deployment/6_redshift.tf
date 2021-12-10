##################################################################
########### Redshift Creation Through Modules ###########
module "redshift" {
    source = "./modules/redshift"
    
    vpc_id     = module.main_vpc.vpc.id
    subnet_ids = concat(module.main_vpc.data_sn.*.id)
}
########### Security Group permissions adding adding ###########
resource "aws_security_group_rule" "airflow_redshift-ib1" {
  type      = "ingress"
  from_port = 5439
  to_port   = 5439
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_ws.id

  security_group_id = module.redshift.sg
}
resource "aws_security_group_rule" "airflow_redshift-ib2" {
  type      = "ingress"
  from_port = 5439
  to_port   = 5439
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_sc.id

  security_group_id = module.redshift.sg
}
resource "aws_security_group_rule" "airflow_redshift-ib3" {
  type      = "ingress"
  from_port = 5439
  to_port   = 5439
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_wk.id

  security_group_id = module.redshift.sg
}
########### SNS Subscriptions ###########
resource "aws_sns_topic" "redshift" {
  name = "redshift-alerting"
}
########### SNS Topic Subscription ###########
resource "aws_sns_topic_subscription" "redshift_email" {
  topic_arn = aws_sns_topic.redshift.arn
  protocol  = "email"
  endpoint  = var.airflow_gui.email
}
########### Redshift Metric Alarm Example ###########
resource "aws_cloudwatch_metric_alarm" "redshift_cpu" {
  alarm_name                = "redshift-cpu-overutilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/Redshift"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "CPU Utilization for Redshift"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.redshift.arn]
  
  dimensions = {
      ClusterIdentifier = module.redshift.cluster_info.id
  }
}
resource "aws_cloudwatch_metric_alarm" "redshift_connection" {
  alarm_name                = "redshift-db-conn-high"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "DatabaseConnections"
  namespace                 = "AWS/Redshift"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "5"
  alarm_description         = "Redshift External Database Connections"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.redshift.arn]
  
  dimensions = {
      ClusterIdentifier = module.redshift.cluster_info.id
  }
}
resource "aws_cloudwatch_metric_alarm" "redshift_net_out" {
  alarm_name                = "redshift-throughput-out"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "NetworkTransmitThroughput"
  namespace                 = "AWS/Redshift"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "700000"
  alarm_description         = "Redshift Outbound Throughput"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.redshift.arn]
  
  dimensions = {
      ClusterIdentifier = module.redshift.cluster_info.id
  }
}
resource "aws_cloudwatch_metric_alarm" "redshift_net_in" {
  alarm_name                = "redshift-throughput-in"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "NetworkReceiveThroughput"
  namespace                 = "AWS/Redshift"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "20000"
  alarm_description         = "Redshift Inbound Throughput"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.redshift.arn]
  
  dimensions = {
      ClusterIdentifier = module.redshift.cluster_info.id
  }
}
