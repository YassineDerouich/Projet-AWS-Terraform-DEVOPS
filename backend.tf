resource "aws_launch_template" "backend_lt" {
  name_prefix   = "backend-template-"
  image_id      = data.aws_ami.debian.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.sg_backend.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" 
    http_put_response_hop_limit = 1
  }

  user_data = base64gzip(file("${path.module}/init_backend.sh"))
}

resource "aws_autoscaling_group" "backend_asg" {
  name                = "backend-asg"
  vpc_zone_identifier = [aws_subnet.private_subnet.id, aws_subnet.private_subnet2.id]
  
  desired_capacity    = 1
  min_size            = 1
  max_size            = 4

  target_group_arns   = [aws_lb_target_group.tg_backend.arn]

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "backend-scalable"
    propagate_at_launch = true
  }
}