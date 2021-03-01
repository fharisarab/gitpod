
#
# Kubernetes Node Group
#

locals {
  node_group_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]
  boot_strap_arguments = ""
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
data "aws_iam_policy_document" "node_group" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
#   policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
#   role = aws_iam_role.node_group.name
# }

# resource "aws_iam_policy" "cluster_autoscaler_policy" {
#   name        = "ClusterAutoScaler"
#   description = "Give the worker node running the Cluster Autoscaler access to required resources and actions"
#   policy = <<-EOF
#     {
#       "Version": "2012-10-17",
#       "Statement": [
#         {
#           "Effect": "Allow",
#           "Action": [
#             "autoscaling:DescribeAutoScalingGroups",
#             "autoscaling:DescribeAutoScalingInstances",
#             "autoscaling:DescribeLaunchConfigurations",
#             "autoscaling:DescribeTags",
#             "autoscaling:SetDesiredCapacity",
#             "autoscaling:TerminateInstanceInAutoScalingGroup"
#           ],
#           "Resource": "*"
#         }
#       ]
#     }
#   EOF
# }

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "node_group" {
  name               = "gitpod-node-group"
  assume_role_policy = data.aws_iam_policy_document.node_group.json
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "node_group" {
  count      = length(local.node_group_policies)
  role       = aws_iam_role.node_group.name
  policy_arn = local.node_group_policies[count.index]
}


resource "aws_launch_template" "node_group" {
  name = "${var.cluster.name}-launch-template"

  # block_device_mappings {
  #   device_name = "/dev/sda1"
  #   ebs {
  #     volume_size = 20
  #   }
  # }

  # capacity_reservation_specification {
  #   capacity_reservation_preference = "open"
  # }

  # cpu_options {
  #   core_count       = 4
  #   threads_per_core = 2
  # }

  # credit_specification {
  #   cpu_credits = "standard"
  # }

  # disable_api_termination = true

  # ebs_optimized = true

  image_id = "ami-087cb8f7a42d11345"

  instance_type = "m5.large"

  monitoring {
    enabled = true
  }

  # network_interfaces {
  #   device_index = 0
  #   security_groups = [
  #     aws_security_group.nodes.id,
  #     aws_security_group.nodes_private.id,
  #   ]
  # }

  vpc_security_group_ids = [
    aws_security_group.nodes.id,
  ]

  user_data = base64encode(templatefile("${path.module}/templates/user-data.tpl", {
    ClusterName = var.cluster.name,
    BootstrapArguments = local.boot_strap_arguments
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      "kubernetes.io/cluster/${var.cluster.name}" = "owned"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.gitpod.name
  node_group_name = "${var.cluster.name}-nodegroup1"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  launch_template {
    id = aws_launch_template.node_group.id
    version = aws_launch_template.node_group.latest_version
  }


  depends_on = [
    aws_iam_role_policy_attachment.node_group,
  ]
}
