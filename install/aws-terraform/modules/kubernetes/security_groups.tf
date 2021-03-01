# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "cluster" {
  name        = "${var.cluster.name}-sg"
  description = "Communication between the control plane and worker nodes in group"
  vpc_id      = aws_vpc.gitpod.id

  tags = {
    Name                                        = "${var.cluster.name}-sg"
    "kubernetes.io/cluster/${var.cluster.name}" = "owned"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "nodes" {
  name        = "${var.cluster.name}-nodes-sg"
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = aws_vpc.gitpod.id

  tags = {
    Name                                        = "${var.cluster.name}-nodes-sg"
    "kubernetes.io/cluster/${var.cluster.name}" = "owned"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "cluster_ingress_self" {
  protocol                 = "-1"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.cluster.id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  protocol                 = "-1"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "cluster_egress_all" {
  protocol          = "-1"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  type              = "egress"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "nodes_ingress_self" {
  protocol                 = "-1"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.nodes.id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "nodes_ingress_cluster" {
  protocol                 = "-1"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "nodes_egress_all" {
  protocol          = "-1"
  security_group_id = aws_security_group.nodes.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  type              = "egress"
}
