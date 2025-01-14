### GENERAL
variable "app_name" {
  type = string
}

### ATLAS
variable "atlas_project_id" {
  type = string
}
variable "atlas_user_password" {
  type = string
}
#variable "atlas_user_password_prod" {
#  type = string
#}
variable "mongodbatlas_private_key" {
  type = string
}
variable "mongodbatlas_public_key" {
  type = string
}

### GCP
variable "gcp_machine_type" {
  type = string
}

### cloudflare
#variable "cloudflare_api_token" {
#  type = string
#}
variable "cloudflare_api_key" {
  type = string
}
variable "cloudflare_account_id" {
  type = string
}

variable "domain" {
  type = string
}
