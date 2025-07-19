variable "site_name" {
  description = "Domain name for the site"
  type        = string
}

variable "base_domain" {
  description = "Base domain for hosted zone lookup"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
