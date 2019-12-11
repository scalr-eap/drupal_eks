terraform {
  backend "remote" {
    hostname = "my.scalr.com"
    organization = "xxxxxxxxxxxxxxx"
    workspaces {
      name = "drupal-eks"
    }
  }
}

provider "aws" {
    access_key = "${var.scalr_aws_access_key}"
    secret_key = "${var.scalr_aws_secret_key}"
    region     = var.region
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = "${data.aws_eks_cluster.this.endpoint}"
  cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)}"
  token                  = "${data.aws_eks_cluster_auth.this.token}"
  load_config_file       = false
}

resource "kubernetes_pod" "this_pod" {
  metadata {
    name = "${var.service_name}-pod"
    labels = {
      App = "${var.service_name}-pod"
    }
  }
  spec {
    container {
      image = "drupal"
      name  = "${var.service_name}-ct"
      port {
        container_port = 80
      }
    }
  }
}

resource "kubernetes_service" "this_svc" {
  metadata {
    name = "${var.service_name}-svc"
  }
  spec {
    selector = {
      App = "${kubernetes_pod.this_pod.metadata.0.labels.App}"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = "${kubernetes_service.this_svc.load_balancer_ingress.0.ip}"
}

output "lb_hostname" {
  value = "${kubernetes_service.this_svc.load_balancer_ingress.0.hostname}"
}
