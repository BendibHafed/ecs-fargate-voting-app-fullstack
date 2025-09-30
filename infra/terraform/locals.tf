locals {
  vpc_cidr               = "10.0.0.0/16"
  vpc_name               = "voting-app-vpc"
  azs                    = slice(data.aws_availability_zones.available.names, 0, 3)
  backend_container_name = "backend"
  backend_container_port = 5000
  db_postgres_port       = 5432
  db_allocated_storage   = 20
}
