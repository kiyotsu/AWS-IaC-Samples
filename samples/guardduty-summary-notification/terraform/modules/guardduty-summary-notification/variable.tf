
variable "env" {
  type        = string
  description = <<-EOT
  (Required) This variable is used as part of the resource name.
  Indicates the environment to deploy to.
  EOT
}

variable "system_name" {
  type        = string
  default     = "guardduty-summary-notification"
  description = "This variable is used as part of the resource name"
}

variable "severity_threshold" {
  type        = number
  default     = 0.0
  description = "The severity threshold for filtering GuardDuty findings."
}
