##################################################################
########### Bucket Creation ###########
resource "aws_s3_bucket" "dags" {
  bucket_prefix = "dags-bucket-"
  acl           = "private"

  versioning {
    enabled = true
  }
  
}
##################################################################
########### Lambda Function Creation ###########
### Lambda IAM Role
resource "aws_iam_role" "dag_upload_lambda" {
    name = "dag_upload_lambda"

    assume_role_policy = file("./dag/lambda_iam_assume.json")
}
### EFS and S3 Permissions
resource "aws_iam_policy" "dag_upload_lambda_efs_s3" {
    name        = "dag_upload_lambda_efs_s3"
    description = "DAG Upload through Lambda using S3 and EFS"

    policy = templatefile("./dag/lambda_efs_s3_policy.tpl", { 
      s3_arn  = aws_s3_bucket.dags.arn
      efs_arn = aws_efs_file_system.airflow_dag.arn
    })
}
### Policy Attachment
resource "aws_iam_role_policy_attachment" "dag_upload_lambda_vpc" {
  role       = aws_iam_role.dag_upload_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_role_policy_attachment" "dag_upload_lambda_efs_s3" {
  role       = aws_iam_role.dag_upload_lambda.name
  policy_arn = aws_iam_policy.dag_upload_lambda_efs_s3.arn
}
### Security Group Creation
resource "aws_security_group" "dag_lambda" {
  name        = "dag-lambda"
  description = "DAG Uploader Lambda"
  vpc_id      = module.main_vpc.vpc.id

  tags = {
    Name = "dag-lambda"
  }
}
resource "aws_security_group_rule" "dag_lambda-ob1" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.dag_lambda.id
}
### Lambda File ZIP
data "archive_file" "dag_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/dag/dag_sync"
  output_path = "${path.module}/dag/dag_sync.zip"
}
### Lambda Creation
resource "aws_lambda_function" "dag_sync" {
  filename         = data.archive_file.dag_lambda.output_path
  source_code_hash = data.archive_file.dag_lambda.output_base64sha256
  function_name    = "dag_sync"
  role             = aws_iam_role.dag_upload_lambda.arn
  handler          = "dag_sync.dag_sync"

  runtime = "python3.9"

  file_system_config {
    arn              = aws_efs_access_point.airflow_dag.arn
    local_mount_path = "/mnt/efs"
  }

  vpc_config { 
      subnet_ids         = concat(module.main_vpc.private_sn.*.id)
      security_group_ids = [aws_security_group.dag_lambda.id]
  }

  depends_on = [
    aws_efs_mount_target.airflow_dag
  ]


}
##################################################################
########### S3 Notification (Permission) ###########
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromS3Notification"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dag_sync.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.dags.arn
}
########### S3 Notification (Lambda Trigger) ###########
resource "aws_s3_bucket_notification" "dag_lambda_trigger" {
  bucket = aws_s3_bucket.dags.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.dag_sync.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_suffix       = ".py"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.dag_sync.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_suffix       = ".sql"
  }
}