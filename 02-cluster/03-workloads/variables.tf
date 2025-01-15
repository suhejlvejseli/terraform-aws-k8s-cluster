variable "master_instance_type" {
  description = "AWS EC2 instance type"
  default = "t2.medium"
}

variable "worker_instance_type" {
  description = "AWS EC2 instance type"
  default = "t2.medium"
}

variable "ami_id" {
  description = "EC2 AMI image to use"
  default = "ami-0a628e1e89aaedf80"
}

variable "key_pair_name" {
  default = "cluster-key"
}

variable "number_of_worker_nodes" {
  description = "Number of Worker Nodes that will be join the cluster"
  default = 2
}