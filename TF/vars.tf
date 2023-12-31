variable "LOCATION" {
  description = "Location of AKS Cluster"
  default     = "East US"
}

variable "RG" {
  description = "Resource Group name"
  default     = "Terraform-ELK-RG"
}

# variable "PUBLIC_CERT_DATA" {
#   type    = string
#   default = file("rootcert.txt")

# }