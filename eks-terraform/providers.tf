provider "aws" {
  region     = "eu-west-1"
  version    = ">= 2.38.0"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
}

# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

provider "http" {}
