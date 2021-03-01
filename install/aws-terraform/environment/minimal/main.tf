/**
 * Copyright (c) 2020 Gitpod GmbH. All rights reserved.
 * Licensed under the MIT License. See License-MIT.txt in the project root for license information.
 */

locals {
  kubernetes = {
    cluster_name   = "gitpod${var.project == "" ? "" : "-${var.project}"}"
    version        = "1.16"
    min_node_count = 1
    max_node_count = 3
    instance_type  = "m4.large"
  }
  vpc = {
    name = "gitpod${var.project == "" ? "" : "-${var.project}"}"
  }
  config_output_path = pathexpand("~/.kube/config")
  gitpod = {
    namespace   = "default"
    valuesFiles = []
  }
}

module "kubernetes" {
    source = "../../modules/kubernetes"

    providers = {
        aws = aws
    }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones
data "aws_availability_zones" "available" {
  state = "available"
}

output "name" {
    value = data.aws_availability_zones.available
}

# # Derived from https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster
# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "2.64.0"

#   name                 = "gitpod"
#   cidr                 = "10.0.0.0/16"
#   azs                  = data.aws_availability_zones.available.names
#   private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#   public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
#   enable_nat_gateway   = true
#   single_nat_gateway   = true
#   enable_dns_hostnames = true

#   tags = {
#     "kubernetes.io/cluster/${local.kubernetes.cluster_name}" = "shared"
#   }

#   public_subnet_tags = {
#     "kubernetes.io/cluster/${local.kubernetes.cluster_name}" = "shared"
#     "kubernetes.io/role/elb"                                 = "1"
#   }

#   private_subnet_tags = {
#     "kubernetes.io/cluster/${local.kubernetes.cluster_name}" = "shared"
#     "kubernetes.io/role/internal-elb"                        = "1"
#   }
# }


# module "kubernetes" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "13.2.1"

#   cluster_name       = local.kubernetes.cluster_name
#   cluster_version    = local.kubernetes.version
#   subnets            = module.vpc.public_subnets
#   vpc_id             = module.vpc.vpc_id

#   # Valid options: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/local.tf#L36
#   worker_groups = [
#     {
#       instance_type     = local.kubernetes.instance_type
#       asg_max_size      = local.kubernetes.max_node_count
#       asg_min_size      = local.kubernetes.min_node_count
#       placement_tenancy = "default"

#       tags = [
#         # These tags are required for the cluster-autoscaler to discover this ASG
#         {
#           "key"                 = "k8s.io/cluster-autoscaler/${local.kubernetes.cluster_name}"
#           "value"               = "true"
#           "propagate_at_launch" = true
#         },
#         {
#           "key"                 = "k8s.io/cluster-autoscaler/enabled"
#           "value"               = "true"
#           "propagate_at_launch" = true
#         }
#       ]
#     }
#   ]
# }


# module "registry" {
#   source = "./modules/registry"
#   project = {
#     name = var.project
#   }
#   gitpod               = local.gitpod
#   region               = var.region
#   worker_iam_role_name = module.kubernetes.worker_iam_role_name

#   depends_on = [module.kubernetes.cluster_id]
# }

# module "storage" {
#   source = "./modules/storage"
#   project = {
#     name = var.project
#   }
#   region               = var.region
#   worker_iam_role_name = module.kubernetes.worker_iam_role_name
#   vpc_id               = module.vpc.vpc_id

#   depends_on = [
#     module.kubernetes.cluster_id
#   ]
# }

# module "gitpod" {
#   source       = "./modules/gitpod"
#   gitpod       = local.gitpod
#   domain_name  = var.domain
#   cluster_name = module.kubernetes.cluster_id

#   providers = {
#     helm       = helm
#     kubernetes = kubernetes
#   }

#   auth_providers = []

#   helm = {
#     chart = "${path.root}/${var.chart_location}"
#   }

#   values = [
#     module.registry.values,
#     module.storage.values,
#     <<-EOT
#     version: ${var.image_version}
#     imagePrefix: ${var.image_prefix}

#     # simply setting "{}" does not work as it does not override: https://github.com/helm/helm/issues/5407
#     certificatesSecret:
#       secretName: ""
#     ingressMode: pathAndHost
#     forceHTTPS: ${var.force_https}

#     installation:
#       region: ${var.region}
    
#     components:
#       # Necessary to make minio send the right header to S3 (region headers must match)
#       contentService:
#         remoteStorage:
#           minio:
#             region: ${var.region}
      
#       # make pathAndHost work
#       wsProxy:
#         disabled: false

#       proxy:
#         certbot:
#           enabled: ${var.certbot_enabled}
#           email: ${var.certificate_email}
      
#     EOT
#   ]

#   depends_on = [
#     module.kubernetes.cluster_id
#   ]
# }
