variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "eu-west-3"
}

variable "github_repo" {
  description = "GitHub repo name in lowercase"
  type        = string
}

variable "image_tag" {
  description = "Tag for the backend image"
  type        = string
}

variable "database_url" {
  type        = string
  description = "Database connection string"
}

variable "db_name" {
  type        = string
  description = "Database name string"
}

variable "db_user" {
  type        = string
  description = "Database username string"
}

variable "db_password" {
  type        = string
  description = "Database password string"
}

variable "flask_secret_key" {
  type        = string
  description = "Flask secret key"
}
