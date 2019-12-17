# Create and RDS Instance for Drupal

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = "${data.aws_eks_cluster.this.vpc_config.0.subnet_ids}"

  tags = {
    Name = "Group1"
  }
}

# Note the cluster SG ID is needed to allow the nodes in the cluster to talk to RDS

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "drupal"
  username             = "drupal"
  password             = var.mysql_password
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [ "${data.aws_eks_cluster.this.vpc_config.0.cluster_security_group_id}" ]
  skip_final_snapshot  = true
}

output "db_endpoint" {
  value = aws_db_instance.default.endpoint
}
