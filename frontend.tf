# LE MODÈLE DE SERVEUR 
resource "aws_launch_template" "frontend_lt" {
  name_prefix   = "frontend-template-"
  image_id      = data.aws_ami.debian.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.sg_frontend.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" 
    http_put_response_hop_limit = 1
  }

  # Terraform lira le fichier .sh proprement pour l'Auto Scaling 
  # Terraform va lire le fichier, le compresser en GZIP, puis l'encoder en base64 
  # AWS le décompressera tout seul au démarrage. Ceci fichier contient le code, comme il est long il faut le compresser.
  user_data = base64gzip(file("${path.module}/init_frontend.sh"))
}

# Auto Scaling Group
resource "aws_autoscaling_group" "frontend_asg" {
  name                = "frontend-asg"
  vpc_zone_identifier = [aws_subnet.private_subnet.id, aws_subnet.private_subnet2.id]
  
  desired_capacity    = 1
  min_size            = 1
  max_size            = 4

  # On connecte ces serveurs au Load Balancer 
  target_group_arns   = [aws_lb_target_group.tg_frontend.arn]

  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "frontend-scalable"
    propagate_at_launch = true
  }
}