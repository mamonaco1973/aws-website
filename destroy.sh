#!/bin/bash

############################################
# SET DEFAULT AWS REGION
############################################

# Export the AWS region to ensure all AWS CLI commands run in the correct context
export AWS_DEFAULT_REGION="us-east-1"

############################################
# STEP 1: DESTROY STORAGE(01-infrastructure)
############################################

# Navigate into the storage infrastructure folder
cd 01-storage

# Reinitialize Terraform backend
terraform init

# Destroy all S3 buckets and related resources provisioned earlier
terraform destroy -auto-approve

# Return to project root
cd ..
