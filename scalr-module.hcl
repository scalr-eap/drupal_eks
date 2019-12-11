version = "v1"

variable "region" {
  policy = "cloud.locations"
  conditions = {
  cloud = "ec2"
  }
}

variable "cluster_name" {
  global_variable = "name_fmt"
}

variable "service_name" {
  global_variable = "name_fmt"
}
