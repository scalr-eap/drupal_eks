terraform {
  backend "remote" {
    hostname = "my.scalr.com"
    organization = "org-sfgari365m7sck0"
    workspaces {
      name = "drupal-eks"
    }
  }
}

provider "aws" {
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

# For randomizing names

resource "random_string" "random" {
  length = 6
  special = false
  upper = false
  number = false
}

resource "kubernetes_secret" "mysql" {
  metadata {
    name = "mysql-pass-${random_string.random.result}"
  }

  data = {
    password = var.mysql_password
  }
}

resource "kubernetes_secret" "root" {
  metadata {
    name = "root-pass-${random_string.random.result}"
  }

  data = {
    password = var.root_password
  }
}

resource "kubernetes_pod" "this_pod" {
  metadata {
    name = "${var.service_name}-${random_string.random.result}"
    labels = {
      App = "${var.service_name}-${random_string.random.result}"
    }
  }
  spec {
    container {
      image = "drupal"
      name  = "${var.service_name}-${random_string.random.result}"
      port {
        container_port = 80
      }
      env {
        name = "MYSQL_DATABASE"
        value = "drupal"
      }
      env {
        name = "MYSQL_USER"
        value = "drupal"
      }
      env {
        name  = "MYSQL_ROOT_HOST"
        value = aws_db_instance.default.endpoint
      }
      env {
        name  = "MYSQL_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.mysql.metadata[0].name
            key  = "password"
          }
        }
      }
      env {
        name  = "MYSQL_ROOT_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.root.metadata[0].name
            key  = "password"
          }
        }
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
