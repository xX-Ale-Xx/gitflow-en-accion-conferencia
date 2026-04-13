@echo off
REM Automated Development Environment Deployment Script (Windows)
REM Usage: deploy-dev.bat

setlocal enabledelayedexpansion

REM Color codes alternative (Windows 10+)
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM Configuration
set "SCRIPT_DIR=%~dp0"
set "TERRAFORM_DIR=%SCRIPT_DIR%terraform"
set "DEV_ENV_DIR=%TERRAFORM_DIR%\environments\development"
set "VARS_FILE=%DEV_ENV_DIR%\terraform.tfvars"

echo.
echo %BLUE%[INFO]%NC% === Checking Prerequisites ===
echo.

REM Check for required commands
for %%X in (gcloud.cmd terraform.exe kubectl.exe) do (
    for /f %%A in ('where %%X 2^>nul') do (
        echo %GREEN%[OK]%NC% %%X found
        goto :next_check
    )
    echo %RED%[ERROR]%NC% %%X not found
    echo Please install: gcloud, terraform, and kubectl
    exit /b 1
    :next_check
)

echo.
echo %BLUE%[INFO]%NC% === GCP Authentication ===
echo.

REM Check GCP authentication
gcloud auth list --filter=status:ACTIVE --format=value(account) >nul 2>&1
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% GCP authentication required
    echo Starting GCP authentication...
    call gcloud auth login --cred-type=user --quiet
    if errorlevel 1 (
        echo %RED%[ERROR]%NC% Failed to authenticate with GCP
        exit /b 1
    )
)

echo.
set /p GCP_PROJECT_ID="Enter your GCP Project ID: "

if "!GCP_PROJECT_ID!"=="" (
    echo %RED%[ERROR]%NC% Project ID cannot be empty
    exit /b 1
)

echo %BLUE%[INFO]%NC% Setting GCP project to: !GCP_PROJECT_ID!
call gcloud config set project "!GCP_PROJECT_ID!" 
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Failed to set GCP project
    exit /b 1
)

echo %GREEN%[OK]%NC% GCP project configured: !GCP_PROJECT_ID!

echo.
echo %BLUE%[INFO]%NC% === Enabling Required APIs ===
echo.

for %%A in (
    compute.googleapis.com
    container.googleapis.com
    storage-api.googleapis.com
    cloudresourcemanager.googleapis.com
    iam.googleapis.com
) do (
    echo %BLUE%[INFO]%NC% Enabling %%A...
    call gcloud services enable %%A --quiet 2>nul
)

echo %GREEN%[OK]%NC% APIs enabled

echo.
echo %BLUE%[INFO]%NC% === Creating GCS Buckets ===
echo.

set "DEV_BUCKET=tfstate-!GCP_PROJECT_ID!-dev"

gsutil ls "gs://!DEV_BUCKET!" >nul 2>&1
if errorlevel 1 (
    echo %BLUE%[INFO]%NC% Creating bucket: gs://!DEV_BUCKET!
    call gsutil mb -l us "gs://!DEV_BUCKET!"
    if errorlevel 1 (
        echo %RED%[ERROR]%NC% Failed to create bucket
        exit /b 1
    )
    echo %GREEN%[OK]%NC% Bucket created
) else (
    echo %YELLOW%[WARNING]%NC% Bucket already exists
)

echo.
set /p DOCKER_IMAGE="Enter Docker image URI: "
if "!DOCKER_IMAGE!"=="" (
    set "DOCKER_IMAGE=ghcr.io/your-org/professional-nestjs-backend:latest"
    echo %YELLOW%[WARNING]%NC% Using default: !DOCKER_IMAGE!
)

echo.
echo %BLUE%[INFO]%NC% === Initializing Terraform ===
echo.

cd /d "!DEV_ENV_DIR!"

call terraform init ^
    -backend-config="bucket=!DEV_BUCKET!" ^
    -backend-config="prefix=nestjs-backend/dev" ^
    -upgrade ^
    -no-color

if errorlevel 1 (
    echo %RED%[ERROR]%NC% Terraform initialization failed
    exit /b 1
)

echo %GREEN%[OK]%NC% Terraform initialized

echo.
echo %BLUE%[INFO]%NC% === Validating Configuration ===
echo.

call terraform validate
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Terraform validation failed
    exit /b 1
)

echo %GREEN%[OK]%NC% Terraform configuration is valid

echo.
echo %BLUE%[INFO]%NC% === Planning Deployment ===
echo.

set "PLAN_FILE=!DEV_ENV_DIR!\terraform.tfplan"

call terraform plan -out="!PLAN_FILE!" -no-color
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Terraform plan failed
    exit /b 1
)

echo %GREEN%[OK]%NC% Terraform plan created

echo.
set /p CONFIRM="Do you want to proceed? (yes/no): "

if not "!CONFIRM!"=="yes" (
    echo Deployment cancelled
    exit /b 0
)

echo.
echo %BLUE%[INFO]%NC% === Applying Configuration (10-15 minutes) ===
echo.

call terraform apply "!PLAN_FILE!"
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Terraform apply failed
    exit /b 1
)

echo %GREEN%[OK]%NC% Deployment complete!

echo.
echo %BLUE%[INFO]%NC% === Cluster Information ===
echo.

for /f %%A in ('terraform output -raw cluster_name 2^>nul') do set "CLUSTER_NAME=%%A"
for /f %%A in ('terraform output -raw configure_kubectl 2^>nul') do set "KUBECTL_CMD=%%A"

if not "!KUBECTL_CMD!"=="" (
    echo %BLUE%[INFO]%NC% Configuring kubectl...
    call !KUBECTL_CMD!
    echo %GREEN%[OK]%NC% kubectl configured
)

echo.
echo %YELLOW%Next Steps:%NC%
echo 1. kubectl get pods -o wide
echo 2. kubectl get svc nestjs-api
echo 3. kubectl logs -l app.kubernetes.io/name=nestjs-api -f

echo.
pause
