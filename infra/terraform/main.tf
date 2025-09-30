
##################################################
# 1. VPC
##################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = local.vpc_name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "prod"
    Project     = "ECS-Fargate-Voting-App-FullStack"
  }
}

##################################################
# 2. RDS
##################################################

module "db" {
  source                 = "terraform-aws-modules/rds/aws"
  version                = "~> 6.0"
  identifier             = "voting-app-db"
  engine                 = "postgres"
  engine_version         = "16"
  family                 = "postgres16"
  instance_class         = "db.t3.micro"
  allocated_storage      = local.db_allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = local.db_postgres_port
  publicly_accessible    = false
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.db_sg.security_group_id]
  create_db_subnet_group = true
  db_subnet_group_name   = "voting-app-db-subnet-group"
}

##################################################
# 3. Security Groups
##################################################

# DB Security Group
module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "voting-db-sg"
  description = "PostgreSQL DB instance security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = local.db_postgres_port
      to_port     = local.db_postgres_port
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = {
    Name = "postgresql-security-group"
  }
}

# ALB Security Group
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
  tags = {
    Name = "Application-Load-Balancer-security-group"
  }
}

##################################################
# 4. Target Group & Listener for ALB 
##################################################

resource "aws_lb_target_group" "backend" {
  name        = "voting-backend-tg"
  port        = local.backend_container_port
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

##################################################
# 5. ALB (Application Load Balancer)
##################################################

resource "aws_lb" "backend" {
  name               = "voting-backend-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]
}

##################################################
# 6. ECS (Module-based)
##################################################

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "voting-app-cluster"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 1
      base   = 1
    }
  }

  services = {
    voting-backend = {
      cpu    = 256
      memory = 512

      container_definitions = {
        backend = {
          cpu       = 256
          memory    = 512
          essential = true
          image     = "ghcr.io/${var.github_repo}/voting-app-backend:${var.image_tag}"
          portMappings = [
            {
              name          = local.backend_container_name
              containerPort = local.backend_container_port
              protocol      = "tcp"
            }
          ]
          environment = [
            { name = "FLASK_CONFIG", value = "ProductionConfig" },
            { name = "DATABASE_URL", value = var.database_url },
            { name = "FLASK_SECRET_KEY", value = var.flask_secret_key },
            { name = "FLASK_DEBUG", value = "0" }
          ]

          enable_cloudwatch_logging = true
        }
      }

      load_balancer = {
        service = {
          target_group_arn = aws_lb_target_group.backend.arn
          container_name   = local.backend_container_name
          container_port   = local.backend_container_port
        }
      }

      subnet_ids = module.vpc.private_subnets

      security_group_ingress_rules = {
        alb_http = {
          description                  = "Allow ALB to reach ECS tasks"
          from_port                    = local.backend_container_port
          to_port                      = local.backend_container_port
          ip_protocol                  = "tcp"
          referenced_security_group_id = module.alb_sg.security_group_id
        }
      }
      security_group_egress_rules = {
        all = {
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
    }
  }

  tags = {
    Environment = "prod"
    Project     = "ECS-Fargate-Voting-App-FullStack"
  }
}






