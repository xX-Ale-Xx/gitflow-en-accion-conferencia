terraform {
  backend "gcs" {
    bucket = "dev-tfstate-bucket"
    prefix = "nestjs-backend/dev"
  }
}
