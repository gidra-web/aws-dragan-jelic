data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_launch_template" "instance_lt" {
  name          = "${var.acc}-instance-launch-template"
  image_id      = data.aws_ssm_parameter.amazon_linux.value
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.asg_sg.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh",
    {
      ecr_repository_url = aws_ecr_repository.ecr_repo.repository_url
      aws_region         = var.aws_region
      image_tag          = "latest"
    }
  ))

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.acc}-instance"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.acc}-instance-volume"
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  max_size         = var.asg_max
  min_size         = var.asg_min
  desired_capacity = var.asg_desired

  vpc_zone_identifier       = values(aws_subnet.private)[*].id
  health_check_type         = "ELB"
  health_check_grace_period = 300

  target_group_arns = [aws_lb_target_group.asg_tg.arn]


  launch_template {
    id      = aws_launch_template.instance_lt.id
    version = aws_launch_template.instance_lt.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.acc}-asg"
    propagate_at_launch = true
  }
}

#
