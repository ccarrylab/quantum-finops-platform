variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "guardrail-ai"
}

variable "alert_email" {
  description = "Email for critical alerts"
  type        = string
  default     = "admin@example.com"
}

variable "retention_days" {
  description = "Days to retain audit logs"
  type        = number
  default     = 2557
}
