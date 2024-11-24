provider "aws" {
  region = "eu-west-2"
  profile = "euteam1"
}

terraform {
  backend "s3" {
    bucket         = "s3-bucket-trial2"
    key            = "infra/tfstate"
    dynamodb_table = "dynamodb-table-trial2"
    region         = "eu-west-2"
    # encrypt = true
    profile = "euteam1"
  }
}

provider "vault" {
  address = "https://vault.dobetabeta.shop"
  #login to vault server and pick the token
  token   = file("./token.txt")
  # token = "s.q99pWTj2kQhHFCxSZ5epRXrR"
}

data "vault_generic_secret" "vault-secret" {
  path = "secret/database"
}

data "vault_generic_secret" "vault-secret-nr" {
  path = "secret/newrelic"
}