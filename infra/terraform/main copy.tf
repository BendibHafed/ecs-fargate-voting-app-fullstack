module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "voting-app-vpc"
  cidr = local.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = [for i, az in data.aws_availability_zones.available.names : cidrsubnet(local.vpc_cidr, 8, i)]
  public_subnets  = [for i, az in data.aws_availability_zones.available.names : cidrsubnet(local.vpc_cidr, 8, i + 100)]


  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "prod"
    Project     = "ECS-Fargate-Voting-App"
  }
}

module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "voting-db-sg"
  description = "Complete PostgreSQL example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = {
    Name = "postgresql-security-group"
  }
}


module "db" {
  source                 = "terraform-aws-modules/rds/aws"
  version                = "~> 6.0"
  identifier             = "voting-app-db"
  engine                 = "postgres"
  engine_version         = "16"
  family                 = "postgres16"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = 5432
  publicly_accessible    = false
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.db_sg.security_group_id]
  create_db_subnet_group = true
  db_subnet_group_name   = "voting-app-db-subnet-group"
}

resource "aws_ecs_cluster" "voting" {
  name = "voting-app-cluster"
}

resource "aws_iam_role" "ecs_execution" {
  name = "ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_logs" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "voting-app-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "ghcr.io/${var.github_repo}/voting-app-backend:${var.image_tag}"
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "FLASK_CONFIG", value = "ProductionConfig" },
        { name = "DATABASE_URL", value = var.database_url },
        { name = "FLASK_SECRET_KEY", value = var.flask_secret_key },
        { name = "FLASK_DEBUG", value = "1" }
      ]
      logConfiguration = {
        LogDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/voting-app-backend"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "voting-backend-service"
  cluster         = aws_ecs_cluster.voting.id
  task_definition = aws_ecs_task_definition.backend.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [module.ecs_sg.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.backend]

}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "voting-alb-sg"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP from anywhere"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "ecs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "voting-ecs-sg"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 5000
      to_port                  = 5000
      protocol                 = "tcp"
      description              = "App traffic from ALB"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_lb" "backend" {
  name               = "voting-backend-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]
}

resource "aws_lb_target_group" "backend" {
  name        = "voting-backend-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  health_check {
    path                = "/healthz"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
