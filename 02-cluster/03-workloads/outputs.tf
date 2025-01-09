output "instance_msr_public_ip" {
  description = "Public address IP of master"
  value       = aws_instance.master.public_ip
}

output "instance_wrks_public_ip" {
  description = "Public address IP of worker"
  value       = aws_instance.worker.*.public_ip
}