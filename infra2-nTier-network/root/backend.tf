# store the terraform state file in s3

terraform {
  backend "s3" {
    bucket = "play102-cluster"
    key    = "play102-state.tfstate"
    region = "us-east-1"
    access_key = "STATE_ACCOUNT_ACCESS_KEY"
    secret_key = "STATE_ACCOUNT_SECRET_KEY"
  }
}
