terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration should be provided via backend config file
    # terraform init -backend-config=backend-<env>.hcl
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  alias  = "frontend"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["private*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["public*"]
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

module "alb" {
  source = "./modules/alb"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = var.vpc_id
  container_port            = var.container_port
  public_subnet_ids          = data.aws_subnets.public.ids
  alb_deletion_protection   = var.alb_deletion_protection
  cloudfront_prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
}

module "ecs_service" {
  source = "./modules/ecs-service"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = var.vpc_id
  container_port        = var.container_port
  fargate_cpu           = var.fargate_cpu
  fargate_memory        = var.fargate_memory
  desired_count         = var.desired_count
  public_subnet_ids     = data.aws_subnets.public.ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  log_retention_days    = var.log_retention_days
  ecr_repository_url    = var.ecr_repository_url
  image_tag             = var.image_tag
  node_env              = var.node_env

  depends_on = [
    module.alb
  ]
}

module "waf" {
  source = "./modules/waf"

  project_name   = var.project_name
  environment    = var.environment
  waf_rate_limit = var.waf_rate_limit
  alb_arn        = module.alb.alb_arn
}

module "autoscaling" {
  source = "./modules/autoscaling"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = module.ecs_service.ecs_cluster_name
  service_name = module.ecs_service.ecs_service_name
  min_capacity = var.min_capacity
  max_capacity = var.max_capacity
}

module "static_cdn" {
  source = "./modules/static-cdn"

  providers = {
    aws          = aws
    aws.frontend = aws.frontend
  }

  project_name           = var.project_name
  environment            = var.environment
  cloudfront_price_class = var.cloudfront_price_class
  alb_dns_name           = module.alb.alb_dns_name
  alb_id                 = module.alb.alb_id
}
