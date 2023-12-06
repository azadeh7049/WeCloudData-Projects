#Launch template
resource "aws_launch_template" "launch_template" {
  name = "Launch_template"

  block_device_mappings {
    device_name = "/dev/sdf"
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }


  instance_type = "t2.micro"

  key_name = "as-key2"


  network_interfaces {
    associate_public_ip_address = true
  }

  placement {
    availability_zone = "us-east-1b"
  }


  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Project 2 ec2 template"
    }
  }

}

resource "aws_launch_configuration" "l_config" {
  name                        = "project2_l_config"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = "as-key"
  security_groups             = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  lifecycle {
    create_before_destroy = true
  }
}

#Load balancer
resource "aws_lb" "load_balancer" {
  name               = "project2-application-lb"
  load_balancer_type = "application"
  internal           = false
  subnets = [
    aws_subnet.project2_public_us_east_1a.id,
    aws_subnet.project2_private_us_east_1b.id,
  ]
  security_groups = [aws_security_group.allow_ssh.id]
}



# Create target group for port 80 (HTTP)
resource "aws_lb_target_group" "target_group_http" {
  name     = "target_group_http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.output_vpc.id

  health_check {
    path    = "/"
    matcher = 200
  }
}

# Create target group for port 443 (HTTPS)
resource "aws_lb_target_group" "target_group_https" {
  name     = "target_group_https"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.output_vpc.id

  health_check {
    path    = "/"
    matcher = 200
  }
}

#Listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.load_balancer.arn
  }
}

#Autoscaling
resource "aws_autoscaling_group" "project2_asg" {
  name             = "project2_asg"
  min_size         = 1
  desired_capacity = 2
  max_size         = 4

  health_check_type = "ELB"
  load_balancers = [
    aws_lb.load_balancer.id
  ]
  launch_configuration = aws_autoscaling_group.project2_asg.aws_launch_configuration.l_config
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  vpc_zone_identifier = [
    aws_subnet.project2_public_us_east_1a.id,
    aws_subnet.project2_private_us_east_1b.id
  ]
  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}
