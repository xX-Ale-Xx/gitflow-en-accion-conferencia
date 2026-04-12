terraform {
  backend "gcs" {
    # State storage en Google Cloud Storage (GCS)
    # Configurar en cada ambiente:
    # 
    # Development:
    #   terraform init -backend-config="bucket=dev-tfstate-bucket" -backend-config="prefix=nestjs-backend/dev"
    #
    # Production:
    #   terraform init -backend-config="bucket=prod-tfstate-bucket" -backend-config="prefix=nestjs-backend/prod"
  }
}

