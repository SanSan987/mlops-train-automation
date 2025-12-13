variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-1" # Використовуйте свій регіон
}

variable "project_name" {
  description = "Prefix for all AWS resources"
  type        = string
  default     = "mlops-train-automation"
}