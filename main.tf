locals {
  name = "pet-adoption"
}

module "keypair" {
  source = "./module/keypair"
  private-file = "${local.name}-private-key"
  public-file = "${local.name}-public-key"
}

module "bastion-host" {
  source = "./module/bastion-host"
  redhat = "ami-07d4917b6f95f5c2a" #redhat
  subnet-id = module.vpc.public_subnets[0]
  public-key-name = module.keypair.public-key-id
  private-key = module.keypair.private-key-pem
  vpc-id = module.vpc.vpc_id
  name = local.name
}

module "db" {
  source = "./module/db"
  db_username = "petclinic"
  db_password = "petclinic"
  db_subnet_ids = module.vpc.private_subnets
  name = local.name
  vpc_id = module.vpc.vpc_id
  bastion-sg = module.bastion-host.bastion-sg 
}

module "sonarqube" {
  source = "./module/sonarqube"
  name = local.name
  ami = "ami-03ca36368dbc9cfa1" #ubuntu
  keypair = module.keypair.public-key-id
  vpc_id = module.vpc.vpc_id
  subnets = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  newrelic-user-licence = ""
  newrelic-acct-id      = ""
  newrelic-region       = "EU"
  domain = "dobetabeta.shop"
  sonarqube-domain = ""
  subnet_id = module.vpc.public_subnets[0]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "stage" {
  source   = "./module/stage"
  vpc-id   = module.vpc.vpc_id
  subnets               = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  redhat                = "ami-07d4917b6f95f5c2a"
  pub-key               = module.keypair.public-key-id
  vpc-zone-identifier   = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]] 
  nexus-ip              = module.nexus.nexus-ip
  newrelic-user-licence = ""
  newrelic-acct-id      = ""
  newrelic-region       = "EU"
  name = local.name
  domain_name = ""
}

module "nexus" {
  source = "./module/nexus"
  subnet_id = module.vpc.public_subnets[1]
  keypair = module.keypair.public-key-id
  name = local.name
  vpc_id = module.vpc.vpc_id
  subnets = [module.vpc.public_subnets[1], module.vpc.public_subnets[0]]
  domain = ""
  nexus-domain = ""
  newrelic-user-licence = ""
  newrelic-acct-id      = ""
  newrelic-region       = "EU"
}