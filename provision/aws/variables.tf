variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region to deploy resources to"
}

variable "srv_cloud_0" {
  type = object({
    instance_type = string
    instance_name = string
    root_block_device = object({
      v_size = number
      v_type = string
    })
    public_key = string
  })
  description = "Configurations related to the `srv-cloud-0` EC2 instance"
}
