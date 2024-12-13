# Public Subnet 2
resource "aws_subnet" "subnet-pub2" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = cidrsubnet(aws_vpc.ecs-vpc.cidr_block, 8, 2)
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}b"
  tags = {
    Name = "${var.vpc_prefix}-public-2b"
  }
}

# Private Subnet 2
resource "aws_subnet" "subnet-priv2" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = cidrsubnet(aws_vpc.ecs-vpc.cidr_block, 8, 4)
  map_public_ip_on_launch = false
  availability_zone       = "${var.region}b"
  tags = {
    Name = "${var.vpc_prefix}-private-2b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.ecs-vpc.id
  tags = {
    Name = "${var.vpc_prefix}-internet-gateway"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.subnet-pub1.id
  tags = {
    Name = "NAT_gw"
  }
  depends_on = [aws_internet_gateway.internet_gateway]
}

# Route Table for Public Subnet
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.ecs-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.vpc_prefix}-public-route-table"
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.ecs-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.vpc_prefix}-private-route-table"
  }
}

# Route Table Association for Public Subnet 1
resource "aws_route_table_association" "subnet_route" {
  subnet_id      = aws_subnet.subnet-pub1.id
  route_table_id = aws_route_table.route_table.id
}

# Route Table Association for Public Subnet 2
resource "aws_route_table_association" "subnet2_route" {
  subnet_id      = aws_subnet.subnet-pub2.id
  route_table_id = aws_route_table.route_table.id
}

# Route Table Association for Private Subnet 1
resource "aws_route_table_association" "priv_subnet1_route" {
  subnet_id      = aws_subnet.subnet-priv1.id
  route_table_id = aws_route_table.private_route_table.id
}

# Route Table Association for Private Subnet 2
resource "aws_route_table_association" "priv_subnet2_route" {
  subnet_id      = aws_subnet.subnet-priv2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Security Group for ALB HTTP Traffic
resource "aws_security_group" "alb-http-sg" {
  vpc_id = aws_vpc.ecs-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-http-sg"
  }
}

# Security Group for ECS Cluster Nodes
resource "aws_security_group" "ecs-cluster-sg" {
  vpc_id = aws_vpc.ecs-vpc.id

  ingress {
    from_port       = 32153
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-http-sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-cluster-sg"
  }
}

# Key Pair for ECS Nodes
resource "aws_key_pair" "ecs-node-kp" {
  key_name   = "ecs-node-key"
  public_key = var.public_key
}

# Launch Template
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template"
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.ecs-node-kp.key_name
  security_group_ids = [aws_security_group.ecs-cluster-sg.id]
  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.instance_name_prefix}"
    }
  }

  user_data = base64encode(data.template_file.user_data.rendered)
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs_asg" {
  vpc_zone_identifier = [aws_subnet.subnet-priv1.id, aws_subnet.subnet-priv2.id]
  launch_template {
    launch_template_name = aws_launch_template.ecs_lt.name
    version             = "$Latest"
  }
  min_size = 1
  max_size = 3
  desired_capacity = 2

  health_check_type          = "EC2"
  health_check_grace_period = 300
  force_delete              = true
  tags = [
    {
      key                 = "Name"
      value               = "ecs-asg-instance"
      propagate_at_launch = true
    }
  ]
}

# ALB Configuration
resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.alb-http-sg.id]
  subnets            = [aws_subnet.subnet-pub1.id, aws_subnet.subnet-pub2.id]
  enable_deletion_protection = false

  tags = {
    Name = "ecs-alb"
  }
}

# ALB Listener
resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "ECS App Running"
    }
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "ecs-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn
    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 70
    }
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "cluster-cp" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }
}
