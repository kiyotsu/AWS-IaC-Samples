variable "vpc_id" {
  description = "(Required) The ID of the VPC in which the endpoint will be used."
  type        = string
}

variable "subnet_ids" {
  description = "(Required) The ID of one or more subnets in which to create a network interface for the endpoint. Applicable for endpoints of type GatewayLoadBalancer and Interface. Interface type endpoints cannot function without being assigned to a subnet."
  type        = list(string)
}

variable "subnet_cider_blocks" {
  description = "(Required) One or more subnet CIDRs to which the host connecting to Session Manager belongs."
  type        = list(string)
}

variable "region" {
  description = "(Option) Target Region. Default:data.aws_region"
  type        = string
  default     = null
}
