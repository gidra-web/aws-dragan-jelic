#!/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
# Install Docker
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# Login to ECR
/usr/bin/aws ecr get-login-password --region "${aws_region}" | \
docker login --username AWS --password-stdin "${ecr_repository_url}"

docker pull "${ecr_repository_url}:${image_tag}"
docker run -d -p 80:80 "${ecr_repository_url}:${image_tag}"