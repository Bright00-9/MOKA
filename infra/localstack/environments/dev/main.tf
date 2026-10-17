module "networking" {
  source = "../../modules/networking"

  project_name = "moka"
  environment  = "dev"
  vpc_cidr     = "10.20.0.0/16"
  az_count     = 2
}