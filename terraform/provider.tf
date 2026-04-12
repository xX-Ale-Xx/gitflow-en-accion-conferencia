terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    # State storage en Google Cloud Storage (GCS)
    # Configurar en cada ambiente via -backend-config:
    # 
    # Development:
    #   terraform init -backend-config="bucket=dev-tfstate-bucket" -backend-config="prefix=nestjs-backend/dev"
    #
    # Production:
    #   terraform init -backend-config="bucket=prod-tfstate-bucket" -backend-config="prefix=nestjs-backend/prod"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
