terraform {
  backend "s3" {
    bucket         = "ecs-fargate-voting-app-state-bucket"
    key            = "ecs-fargate-voting-app/terraform-tfstate"
    region         = "eu-west-3"
    dynamodb_table = "ecs-fargate-voting-locks"
    encrypt        = true
  }
}