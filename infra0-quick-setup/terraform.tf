terraform {
  required_version = ">= 1.0.0" # specifies the version of terraform we must use.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}