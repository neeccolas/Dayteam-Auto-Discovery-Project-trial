provider "aws" {
  region = "eu-west-3"
  profile = "euteam1"
}

terraform {
  backend "s3" {
    bucket         = "s3-bucket-trial"
    key            = "infra/tfstate"
    dynamodb_table = "dynamodb-table-trial"
    region         = "eu-west-3"
    # encrypt = true
    profile = "euteam1"
  }
}

provider "vault" {
  address = "https://vault.dobetabeta.shop"
  #login to vault server and pick the token
  token = "s.2r8yIx8G5cReQ1OvuFNrWLar"
}

data "vault_generic_secret" "vault-secret" {
  path = "secret/database"
}