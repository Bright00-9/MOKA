# No endpoint overrides, no fake credentials — this talks to real AWS and
# will create real, billable resources. Credentials come from whatever the
# AWS CLI normally uses: `aws configure`, an `AWS_PROFILE` env var, or the
# standard AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY env vars. Set `aws_profile`
# in your tfvars (or leave it null to use the default profile/credentials).
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}
