locals {
  project = "terraform-aws-k8s-cluster"

  default_tags = {
    Project = local.project
    Label   = "Thesis"
  }
}

resource "aws_iam_role" "master_node_role" {
  name = "master-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  depends_on = [ aws_s3_bucket.cluster_bucket ]
}

resource "aws_iam_policy" "master_node_policy" {
  name = "master-node-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::k8s-bucket-workloads/*"
      }
    ]
  })

  depends_on = [ aws_iam_role.master_node_role ]
}

resource "aws_iam_role_policy_attachment" "master_node_attachment" {
  role       = aws_iam_role.master_node_role.name
  policy_arn = aws_iam_policy.master_node_policy.arn

  depends_on = [ aws_iam_policy.master_node_policy ]
}

resource "aws_iam_instance_profile" "master_node_profile" {
  name = "master-node-profile"
  role = aws_iam_role.master_node_role.name

  depends_on = [ aws_iam_role_policy_attachment.master_node_attachment ]
}

resource "aws_iam_role" "worker_node_role" {
  name = "worker-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  depends_on = [ aws_s3_bucket.cluster_bucket ]
}

resource "aws_iam_policy" "worker_node_policy" {
  name = "worker-node-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::k8s-bucket-workloads/*"
      }
    ]
  })

  depends_on = [ aws_iam_role.worker_node_role ]
}

resource "aws_iam_role_policy_attachment" "worker_node_attachment" {
  role       = aws_iam_role.worker_node_role.name
  policy_arn = aws_iam_policy.worker_node_policy.arn

  depends_on = [ aws_iam_policy.worker_node_policy ]
}

resource "aws_iam_instance_profile" "worker_node_profile" {
  name = "worker-node-profile"
  role = aws_iam_role.worker_node_role.name

  depends_on = [ aws_iam_role_policy_attachment.worker_node_attachment ]
}

resource "aws_instance" "master" {
  ami = var.ami_id
  subnet_id = data.terraform_remote_state.networking.outputs.subnet_ids[0]
  instance_type = var.instance_type
  key_name = var.key_pair_name
  associate_public_ip_address = true
  security_groups = [ data.terraform_remote_state.networking.outputs.security_group_id ]

  iam_instance_profile = aws_iam_instance_profile.master_node_profile.name

  root_block_device {
    volume_type = "gp2"
    volume_size = "16"
    delete_on_termination = true
  }

  user_data_base64 = base64encode("${templatefile("scripts/configure_k8s_master.sh", {
    s3_bucket_name = "k8s-bucket-workloads"
  })}")

  depends_on = [ 
    aws_s3_bucket.cluster_bucket 
  ]

  tags = merge({
    Name = "k8s-master-node"
  }, local.default_tags)
  
}

resource "aws_instance" "worker" {
  count = var.number_of_worker_nodes

  ami = var.ami_id
  subnet_id = data.terraform_remote_state.networking.outputs.subnet_ids[0]
  instance_type = var.instance_type
  key_name = var.key_pair_name
  associate_public_ip_address = true
  security_groups = [ data.terraform_remote_state.networking.outputs.security_group_id ]

  iam_instance_profile = aws_iam_instance_profile.worker_node_profile.name

  root_block_device {
    volume_type = "gp2"
    volume_size = "16"
    delete_on_termination = true
  }

  user_data_base64 = base64encode("${templatefile("scripts/configure_k8s_worker.sh", {
    s3_bucket_name = "k8s-bucket-workloads"
    worker_number = "${count.index + 1}"
  })}")

  depends_on = [ 
    aws_s3_bucket.cluster_bucket,
    aws_instance.master
  ]

  tags = merge({
    Name = "k8s-worker-node-${count.index + 1}"
  }, local.default_tags)
}