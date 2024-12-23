output "srv_cloud_0_eip" {
  value       = aws_eip.srv_cloud_0.public_ip
  description = "AWS elastic ip address associated with `srv-cloud-0`"
}
