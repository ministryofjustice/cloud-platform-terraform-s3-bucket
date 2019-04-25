
provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias = "module"
  region = "eu-west-2"
}