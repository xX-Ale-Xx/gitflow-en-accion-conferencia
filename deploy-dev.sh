#!/bin/bash

##############################################################################
# Automated Development Environment Deployment Script
# 
# Usage: ./deploy-dev.sh
# 
# This script automates the complete deployment of the NestJS backend
# to a GCP GKE cluster in the development environment, without any
# manual GCP configuration required.
##############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"
DEV_ENV_DIR="${TERRAFORM_DIR}/environments/development"
VARS_FILE="${DEV_ENV_DIR}/terraform.tfvars"
BACKEND_BUCKET_DEV="dev-tfstate-bucket-$(date +%s | md5sum | cut -c1-8)"
BACKEND_PREFIX="nestjs-backend/dev"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

##############################################################################
# 1. Check Prerequisites
##############################################################################
echo ""
log_info "=== Checking Prerequisites ==="

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Command '$1' not found. Please install it first."
        if [ "$1" = "gcloud" ]; then
            echo "  Download: https://cloud.google.com/sdk/docs/install"
        elif [ "$1" = "terraform" ]; then
            echo "  Download: https://www.terraform.io/downloads.html"
        elif [ "$1" = "kubectl" ]; then
            echo "  Run: gcloud components install kubectl"
        fi
        exit 1
    fi
    log_success "$1 is installed"
}

check_command "gcloud"
check_command "terraform"
check_command "kubectl"

##############################################################################
# 2. Configure GCP Project
##############################################################################
echo ""
log_info "=== Configuring GCP Project ==="

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    log_warning "GCP authentication required"
    log_info "Starting GCP authentication..."
    gcloud auth login --cred-type=user --quiet || {
        log_error "Failed to authenticate with GCP"
        exit 1
    }
fi

# Get project ID from user if not set
read -p "Enter your GCP Project ID: " GCP_PROJECT_ID

if [ -z "$GCP_PROJECT_ID" ]; then
    log_error "Project ID cannot be empty"
    exit 1
fi

# Set the project
log_info "Setting GCP project to: $GCP_PROJECT_ID"
gcloud config set project "$GCP_PROJECT_ID" || {
    log_error "Failed to set GCP project"
    exit 1
}

log_success "GCP project configured: $GCP_PROJECT_ID"

##############################################################################
# 3. Enable Required APIs
##############################################################################
echo ""
log_info "=== Enabling Required GCP APIs ==="

APIS=(
    "compute.googleapis.com"
    "container.googleapis.com"
    "storage-api.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "iam.googleapis.com"
)

for api in "${APIS[@]}"; do
    log_info "Enabling $api..."
    gcloud services enable "$api" --quiet || {
        log_warning "Note: API $api may already be enabled or failed to enable"
    }
done

log_success "APIs enabled"

##############################################################################
# 4. Create GCS Buckets for Terraform State
##############################################################################
echo ""
log_info "=== Creating GCS Buckets for Terraform State ==="

GCLOUD_REGION="us"
REGION="us-central1"

# Function to create bucket if it doesn't exist
create_bucket_if_not_exists() {
    local bucket_name="$1"
    local bucket_location="$2"
    
    if gsutil ls "gs://${bucket_name}" &> /dev/null; then
        log_warning "Bucket gs://${bucket_name} already exists"
    else
        log_info "Creating bucket: gs://${bucket_name}"
        gsutil mb -l "$bucket_location" "gs://${bucket_name}" || {
            log_error "Failed to create bucket $bucket_name"
            exit 1
        }
        log_success "Bucket created: gs://${bucket_name}"
    fi
}

# Create dev bucket (use project ID in name for uniqueness)
DEV_BUCKET="tfstate-${GCP_PROJECT_ID}-dev"
create_bucket_if_not_exists "$DEV_BUCKET" "$GCLOUD_REGION"

##############################################################################
# 5. Update Terraform Variables
##############################################################################
echo ""
log_info "=== Updating Terraform Variables ==="

# Get Docker image from user
read -p "Enter your Docker image URI (e.g., ghcr.io/your-org/professional-nestjs-backend:latest): " DOCKER_IMAGE

if [ -z "$DOCKER_IMAGE" ]; then
    DOCKER_IMAGE="ghcr.io/your-org/professional-nestjs-backend:latest"
    log_warning "Using default Docker image: $DOCKER_IMAGE"
fi

# Update terraform.tfvars
log_info "Updating terraform.tfvars with project ID and image..."
sed -i.bak "s|gcp_project_id.*=.*|gcp_project_id = \"${GCP_PROJECT_ID}\"|" "$VARS_FILE"
sed -i.bak "s|docker_image.*=.*|docker_image = \"${DOCKER_IMAGE}\"|" "$VARS_FILE"

log_success "Terraform variables updated"

##############################################################################
# 6. Initialize Terraform
##############################################################################
echo ""
log_info "=== Initializing Terraform ==="

cd "$DEV_ENV_DIR"

log_info "Running terraform init..."
terraform init \
    -backend-config="bucket=${DEV_BUCKET}" \
    -backend-config="prefix=${BACKEND_PREFIX}" \
    -upgrade \
    -no-color || {
    log_error "Terraform initialization failed"
    exit 1
}

log_success "Terraform initialized"

##############################################################################
# 7. Validate Terraform Configuration
##############################################################################
echo ""
log_info "=== Validating Terraform Configuration ==="

terraform validate || {
    log_error "Terraform validation failed"
    exit 1
}

log_success "Terraform configuration is valid"

##############################################################################
# 8. Plan Terraform Deployment
##############################################################################
echo ""
log_info "=== Planning Terraform Deployment ==="

PLAN_FILE="${DEV_ENV_DIR}/terraform.tfplan"

terraform plan \
    -out="${PLAN_FILE}" \
    -no-color || {
    log_error "Terraform plan failed"
    exit 1
}

log_success "Terraform plan created: $PLAN_FILE"

##############################################################################
# 9. Confirm Before Applying
##############################################################################
echo ""
log_warning "Please review the terraform plan above"
read -p "Do you want to proceed with applying this plan? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log_error "Deployment cancelled by user"
    exit 1
fi

##############################################################################
# 10. Apply Terraform Configuration
##############################################################################
echo ""
log_info "=== Applying Terraform Configuration ==="
log_warning "This may take 10-15 minutes to create the GKE cluster..."

terraform apply "${PLAN_FILE}" || {
    log_error "Terraform apply failed"
    exit 1
}

log_success "Terraform apply completed successfully"

##############################################################################
# 11. Extract Cluster Information
##############################################################################
echo ""
log_info "=== Extracting Cluster Information ==="

CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "unknown")
CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint 2>/dev/null | sed 's/^https:\/\///; s/:443$//')
KUBECTL_CONFIG=$(terraform output -raw configure_kubectl 2>/dev/null)

log_info "Cluster Name: $CLUSTER_NAME"
log_info "Cluster Endpoint: $CLUSTER_ENDPOINT"

##############################################################################
# 12. Configure kubectl
##############################################################################
echo ""
log_info "=== Configuring kubectl ==="

if [ -n "$KUBECTL_CONFIG" ]; then
    log_info "Running: $KUBECTL_CONFIG"
    eval "$KUBECTL_CONFIG" || {
        log_error "Failed to configure kubectl"
        exit 1
    }
    log_success "kubectl configured successfully"
else
    log_warning "Could not retrieve kubectl configuration command"
    log_info "Please run manually:"
    log_info "gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $GCP_PROJECT_ID"
fi

##############################################################################
# 13. Verify Cluster Connection
##############################################################################
echo ""
log_info "=== Verifying Cluster Connection ==="

sleep 5  # Wait a moment for kubeconfig to settle

if kubectl cluster-info &> /dev/null; then
    log_success "Connected to Kubernetes cluster successfully"
    
    # Display cluster info
    log_info "Cluster Information:"
    kubectl cluster-info 2>/dev/null | grep -E "Kubernetes master|CoreDNS" || true
    
    # Check node status
    log_info "Node Status:"
    kubectl get nodes || true
else
    log_warning "Could not verify cluster connection. Please check manually with: kubectl cluster-info"
fi

##############################################################################
# 14. Display Application Information
##############################################################################
echo ""
log_info "=== Application Deployment Information ==="

APP_NAME=$(terraform output -raw kubernetes_app_name 2>/dev/null || echo "nestjs-api")
SERVICE_NAME=$(terraform output -raw kubernetes_service_name 2>/dev/null || echo "nestjs-api")
SERVICE_IP=$(terraform output -raw kubernetes_service_ip 2>/dev/null || echo "pending")

log_success "Application Deployment Complete!"
echo ""
echo "Application Details:"
echo "  Deployment Name: $APP_NAME"
echo "  Service Name: $SERVICE_NAME"
echo "  Service IP: $SERVICE_IP"
echo ""

##############################################################################
# 15. Output Next Steps
##############################################################################
echo ""
log_info "=== Next Steps ==="
echo ""
echo "1. Verify pod deployment:"
echo "   kubectl get pods -o wide"
echo ""
echo "2. Check service status:"
echo "   kubectl get svc $SERVICE_NAME"
echo ""
echo "3. View pod logs:"
echo "   kubectl logs -l app.kubernetes.io/name=$APP_NAME --tail=100 -f"
echo ""
echo "4. Port forward to access locally (if not exposed):"
echo "   kubectl port-forward svc/$SERVICE_NAME 3000:80"
echo ""
echo "5. Destroy environment (when no longer needed):"
echo "   cd $DEV_ENV_DIR"
echo "   terraform destroy"
echo ""

# Cleanup
rm -f "${VARS_FILE}.bak"

log_success "=== Deployment Complete ==="
echo ""
