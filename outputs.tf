output "cloudflare_zone" {
  value       = cloudflare_zone.domain
  description = "Cloudflare Zone resource."
}

output "sendgrid_domain_authentication_domain_id" {
  value       = sendgrid_domain_authentication.domain
  description = "SendGrid domain authentication"
}
