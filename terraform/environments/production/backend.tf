terraform {
  backend "gcs" {
    bucket = "prod-tfstate-bucket"
    prefix = "nestjs-backend/prod"
  }
}
