variable "domain" {
  type        = string
  description = "The domain name for the email."
}

variable "sub_domain" {
  type        = string
  default     = null
  description = "(Optional) The sub-domain for the email."
}

variable "email_recipients" {
  type        = list(any)
  description = "List of e-mail recipients, ie: support@example.org"
}

variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare account ID."
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token."
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "aws_access_key" {
  type        = string
  description = "AWS access key."
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret key."
}

variable "aws_s3_bucket_name" {
  type        = string
  description = "The emails will be stored in this S3 bucket."
}

variable "aws_s3_force_destroy" {
  type    = bool
  default = false
}

variable "sendgrid_ip" {
  type        = string
  description = "SendGrid IP address for the domain."
}

variable "sendgrid_api_key" {
  type        = string
  description = "API Key for Sendgrid."
}

variable "sendgrid_username" {
  type        = string
  description = "SendGrid username for the subuser assigned to the domain."
}

variable "sendgrid_password" {
  type        = string
  description = "SendGrid password for the subuser assigned to the domain."
}

variable "sendgrid_email" {
  type        = string
  description = "E-mail address of the subuser."
}
