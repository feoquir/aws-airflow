# Airflow Environment Creation
## Deployment
1. Fill the example.auto.tfvars file with the required information
2. Copy the example.auto.tfvars to terraform_deployment/
3. Apply the Terraform plan under terraform_deployment/
4. After all elements have been built upload:
    - terraform_deployment/dag/postgres_dag/sql
    - terraform_deployment/dag/postgres_dag/postgres_populate_dag.py
    - terraform_deployment/dag/postgres_dag/postgres_read_dag.py
   To the S3 Bucket Created (bucket prefix: dags-bucket).
5. Ensure all ECS Tasks are on the RUNNING state.
6. (Optional) Based on the uploaded ACM ARN (Frontend Certificate), create a CNAME pointing towards the Load Balancer's DNS Name
7. Access the Webserver via the Load Balancer (HTTPS 443).
8. Gather the admin credentials via SSM Parameters (/production/airflow/gui/pwd)
9. Create new connection towards Postgres based on SSM Parameters (/production/airflow/remote_psql).
10. Create new connection towards Redshift based on SSM parameters (/production/airflow/redshift)
## Terraform Folder/File Anatomy (terraform_deployment/)
- main.tf: 
Provider(s) creation. Potentially could contain external Terraform States.
- 1_networking.tf: 
Creation of networking elements and layout (VPC, Subnets, Routing Tables, NAT Gateways, Application Load Balancers, Security Groups and Security Groups Rules).
- 2_docker_creation.tf: 
Rudimentary yet reliable Airflow Docker creation mechanism based on an EC2 Instance User Data and ECRs.
The Dockerfiles are included under: docker/docker_setup.tpl
- 3_airflow.tf: 
Actual creation of the infrastructure: Includes the building of RDS, SQS (default queue), Cloudwatch LogGroups, ECS Cluster/Services/Task Definitions, IAM roles for ECS Elements, Security Groups, EFS File system/Mount Target/Access Point.
- 4_dag_upload.tf: 
Creation of S3 and Lambda function capable of feeding EFS the DAG files; the creation is triggered by creating/deleting the files on S3.
- 5_external_db_simulate.tf: 
External Database Simulation by adding RDS to the public subnet (without a public Elastic IP address added).
- 6_redshift.tf:
Redshift cluster creation, including SNS topics and CloudWatch Alerts.
- outputs.tf: 
Outputs to be used by other projects (or for visibility).
- variables.tf: 
Definition of variables to be used (including defaults).
- example.auto.tfvars: 
Variable requirements
## Modules
### 3 Layer VPC (3layer_vpc)
- Creates a standard VPC based on provided CIDRs
- Creates Public subnet(s) based on provided CIDRs
- Creates Application (Private) subnet(s) based on provided CIDRs
- Creates Data subnet(s) based on provided CIDRs
- Clears the default Routing Table
- Clears the default Security Group
- Adds an Internet Gateway
- Adds a NAT Gateway (Public IP address leased)
- Routing tables for Public, Application and Data subnet(s)
### Airflow ECS (airflow_ecs)
- Creates the ECS Task Definition (based on the container definition and environment variables).
- Creates the ECS Service per se (webserver vs. scheduler/workers)
### Airflow RDS (airflow_rds)
- Creates RDS DB subnetting
- Creates RDS DB Security Group
- Creates RDS DB instance
- Creates RDS Admin Password
- Creates SSM Parameters for both Celery and SQLAlchemy connections
### Redshift (redshift)
- Creates Redshift Subnet group
- Creates Redshift Security Groups
- Creates Redshift Admin Password
- Creates Redshift IAM Role
- Creates Redshift Cluster
- Creates SSM Parameters store collecting all Redshift important information