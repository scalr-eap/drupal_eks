variable "scalr_aws_secret_key" {}
variable "scalr_aws_access_key" {}

variable "cluster_name" {
  type    = string
  description = "Cluster to deploy to"
}

variable "region" {
  description = "The AWS Region of the Cluster"
  type        = string
}

variable "service_name" {
  description = "Name to be given to the Wordpress service in EKS"
  type        = string
}
