
terraform {
  # @todo: add required_providers. specify version.
  required_version = ">= 0.12"

  backend "s3" {
    encrypt        = true
  }
}
