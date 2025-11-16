variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}