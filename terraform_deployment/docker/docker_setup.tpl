#!/bin/bash
# Update and dependency download
sudo yum update -y
sudo yum install docker git -y
sudo systemctl enable docker
sudo systemctl start docker
# Pulling source docker iamge
sudo docker pull apache/airflow
# Creating working directories
mkdir -p  ~/image_building/webserver ~/image_building/scheduler ~/image_building/worker
# Creation of Airflow Webserver
cat <<EOF > ~/image_building/webserver/Dockerfile
FROM apache/airflow:latest
# Set User for package installation
USER root
RUN apt-get update
# Set User for Airflow configuration
USER airflow
#ARG AIRFLOW_VERSION="2.0.2"
EOF
cd ~/image_building/webserver
sudo docker build . -t airflow-ws:0.0.1
# Airflow Webserver Push
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${ecr_ws_url}
sudo docker tag airflow-ws:0.0.1 ${ecr_ws_url}:latest
sudo docker tag airflow-ws:0.0.1 ${ecr_ws_url}:0.0.1
sudo docker push ${ecr_ws_url}:latest
sudo docker push ${ecr_ws_url}:0.0.1
# Creation of Airflow Scheduler
cat <<EOF > ~/image_building/scheduler/Dockerfile
FROM apache/airflow:latest
# Set User for package installation
USER root
RUN apt-get update
RUN apt install libcurl4-openssl-dev libssl-dev gcc -y
# Set User for Airflow configuration
USER airflow
RUN pip install --no-cache-dir pycurl
#ARG AIRFLOW_VERSION="2.0.2"
EOF
cd ~/image_building/scheduler
sudo docker build . -t airflow-sc:0.0.1
# Airflow Scheduler Push
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${ecr_sc_url}
sudo docker tag airflow-sc:0.0.1 ${ecr_sc_url}:latest
sudo docker tag airflow-sc:0.0.1 ${ecr_sc_url}:0.0.1
sudo docker push ${ecr_sc_url}:latest
sudo docker push ${ecr_sc_url}:0.0.1
# Creation of Airflow Worker
cat <<EOF > ~/image_building/worker/Dockerfile
FROM apache/airflow:latest
# Set User for package installation
USER root
RUN apt-get update
RUN apt install libcurl4-openssl-dev libssl-dev gcc -y
# Set User for Airflow configuration
USER airflow
RUN pip install --no-cache-dir pycurl
#ARG AIRFLOW_VERSION="2.0.2"
EOF
cd ~/image_building/worker
sudo docker build . -t airflow-wk:0.0.1
# Airflow Worker Push
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${ecr_wk_url}
sudo docker tag airflow-wk:0.0.1 ${ecr_wk_url}:latest
sudo docker tag airflow-wk:0.0.1 ${ecr_wk_url}:0.0.1
sudo docker push ${ecr_wk_url}:latest
sudo docker push ${ecr_wk_url}:0.0.1
# Instance Shutdown
sudo shutdown -h now