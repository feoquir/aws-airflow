# Terraform Credentials to be used by Terraform
tf_creds = {
  access_key = "AK_placeholder"
  secret_key = "SK_placeholder"
  region     = "eu-north-1"
}
# RDS Attributes pertaining the creation of the Airflow RDS Instance
rds_attrs = {
  name    = "airflow-psql"
  size    = "db.t3.medium"
  db_name = "prodairflow"
  usr     = "theadmin"
}
# Airflow Webserver Admin Attributes
airflow_gui = {
  email     = "placeholder@placeholder.com"
  firstname = "placeholder"
  lastname  = "placeholder"
  username  = "Admin"
}
# Webserver access IP address
inc_ip = "1.1.1.1/32"
# Frontend Certificate ARN (Uploaded to AWS Certificate Manager within the account)
frontend_certificate = "Placeholder"