terraform {
  cloud {
    organization = "mooawia_org"
    workspaces {
      project = "devops-portfoilio"
      name    = "devops-terraform-portfolio"
    }

  }

  required_providers {
    aws = {

      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  required_version = "~> 1.2"
}