output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = aws_subnet.cluster_subnet[*].id
}

output "security_group_id" {
  value = aws_security_group.cluster_sg.id
}