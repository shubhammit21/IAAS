#Create EC2 AMI in AWS with Packer and create ELB, ASG, LC, SG, AZ with Terraform and commit AWS Environment state to repository repo.

provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["589672567772"] # Canonical
}

# Configuring EC2 instance 
resource "aws_launch_configuration" "sp_app_lc" {
  image_id = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.sp_app_websg.id}"]   # adding securty group
  lifecycle {
    create_before_destroy = true
  }
}

# creating autoscaling 
resource "aws_autoscaling_group" "sp_app_asg" {
  name                 = "terraform-asg-springboot-app-${aws_launch_configuration.sp_app_lc.name}"
  launch_configuration = "${aws_launch_configuration.sp_app_lc.name}"
  availability_zones = ["${data.aws_availability_zones.allzones.names}"]
  min_size             = 2
  max_size             = 5
  load_balancers = ["${aws_elb.elb1.id}"]
  health_check_type = "ELB"
  lifecycle {
    create_before_destroy = true
  }
}

# Creating securty group for sp_app_websg
resource "aws_security_group" "sp_app_websg" {
  name = "security_group_for_sp_app_websg"
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}


# Creating security group for elb
resource "aws_security_group" "elbsg" {
  name = "security_group_for_elb"
  ingress {
    from_port = 80
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

#Creating elb
data "aws_availability_zones" "allzones" {}
resource "aws_elb" "elb1" {
  name = "terraform-elb-springboot-app"
  availability_zones = ["${data.aws_availability_zones.allzones.names}"]
  security_groups = ["${aws_security_group.elbsg.id}"]
  
  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8080/"
      interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  tags = {
    Name = "terraform-elb-springboot-app"
  }
}