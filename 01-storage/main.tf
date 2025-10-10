# Configure the AWS provider block
# This section establishes the configuration for the AWS provider, which is essential for Terraform to communicate with AWS services.
# The provider is responsible for managing and provisioning AWS resources defined in your Terraform code.
# 
# 'region' specifies the AWS region where Terraform will create and manage resources.
# It is critical to set this value correctly, as deploying resources in an incorrect region can lead to higher latency, unexpected costs, or compliance issues.
# 
# Note:
# - Ensure the AWS credentials (e.g., access keys) are properly configured in your environment.
# - Use the AWS CLI, environment variables, or Terraform's native authentication methods for secure credential management.
# - Replace "us-east-1" with the desired region code (e.g., "us-west-1") if deploying to a different AWS region.

provider "aws" {
  region = "us-east-1" # Default region set to US East (N. Virginia). Modify if your deployment requires another region.
}

# ---------------------------------------------
# DATA BLOCK: Resolve Route 53 Hosted Zone
# ---------------------------------------------
data "aws_route53_zone" "selected" {
  name         = var.domain_name        # e.g., "mikes-cloud-solutions.org."
  private_zone = false                  # set true if resolving a private zone
}

# ------------------------------------------------------------------------------------------
# ALIASED PROVIDER FOR CLOUDFRONT/ACM (must be us-east-1)
# ------------------------------------------------------------------------------------------
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
