variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "notebook_instance_type" {
  description = "SageMaker notebook instance type"
  type        = string
  default     = "ml.t3.medium"
}

variable "inference_instance_type" {
  description = "SageMaker inference instance type"
  type        = string
  default     = "ml.m5.xlarge"
}

variable "inference_instance_count" {
  description = "Number of inference instances"
  type        = number
  default     = 2
}

variable "alert_email" {
  description = "Email for prediction alerts"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
