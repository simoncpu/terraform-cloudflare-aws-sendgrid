resource "cloudflare_zone" "domain" {
  account_id = var.cloudflare_account_id
  zone       = var.domain
  jump_start = true
}

resource "cloudflare_record" "MX" {
  zone_id  = cloudflare_zone.domain.id
  name     = "@"
  type     = "MX"
  ttl      = 1
  value    = "inbound-smtp.${var.aws_region}.amazonaws.com"
  priority = 10
}

# verify the domain's identity in SES

resource "aws_ses_domain_identity" "email_domain_identity" {
  domain = var.domain
}

resource "cloudflare_record" "SESToken" {
  zone_id = cloudflare_zone.domain.id
  name    = "_amazonses.${var.domain}"
  value   = aws_ses_domain_identity.email_domain_identity.verification_token
  type    = "TXT"
  ttl     = 1
}

# SPF

resource "cloudflare_record" "SESSPF" {
  zone_id = cloudflare_zone.domain.id
  name    = "@"
  value   = "v=spf1 include:amazonses.com -all"
  type    = "TXT"
  ttl     = 1
}

# DKIM

resource "aws_ses_domain_dkim" "email_dkim" {
  domain = aws_ses_domain_identity.email_domain_identity.domain
}

resource "cloudflare_record" "SESDKIM" {
  count   = 3
  zone_id = cloudflare_zone.domain.id
  name    = "${element(aws_ses_domain_dkim.email_dkim.dkim_tokens, count.index)}._domainkey.${var.domain}"
  value   = "${element(aws_ses_domain_dkim.email_dkim.dkim_tokens, count.index)}.dkim.amazonses.com"
  type    = "CNAME"
  ttl     = 1
}

# Create S3 bucket for receiving emails

resource "aws_s3_bucket" "mailbox" {
  bucket        = "${var.aws_s3_bucket_name}/${var.domain}"
  force_destroy = var.aws_s3_force_destroy
}

resource "aws_s3_bucket_acl" "mailbox" {
  bucket = aws_s3_bucket.mailbox.id
  acl    = "private"
}

data "aws_iam_policy_document" "mailbox" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.mailbox.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "mailbox" {
  bucket = aws_s3_bucket.mailbox.id
  policy = data.aws_iam_policy_document.mailbox.json
}


# Create a new rule set
resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = var.domain
}

resource "aws_ses_receipt_rule" "main" {
  name          = "mailbox"
  rule_set_name = aws_ses_receipt_rule_set.main.rule_set_name
  recipients    = var.email_recipients
  enabled       = true
  scan_enabled  = true
  s3_action {
    bucket_name       = var.aws_s3_bucket_name
    object_key_prefix = "mailbox/${var.domain}"
    position          = 1
  }

  # This is a workaround for this issue:
  # https://github.com/hashicorp/terraform-provider-aws/issues/7917

  depends_on = [aws_s3_bucket_policy.mailbox]
}

# Activate rule set
resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = aws_ses_receipt_rule_set.main.rule_set_name
}

resource "sendgrid_subuser" "subuser" {
  username = var.sendgrid_username
  email    = var.sendgrid_email
  password = var.sendgrid_password
  ips      = [var.sendgrid_ip]
}

resource "sendgrid_domain_authentication" "domain" {
  domain             = var.domain
  subdomain          = var.sub_domain
  automatic_security = true
  valid              = true
}

resource "cloudflare_record" "domain" {
  count   = 3
  zone_id = cloudflare_zone.domain.id
  name    = sendgrid_domain_authentication.domain.dns[count.index].host
  value   = sendgrid_domain_authentication.domain.dns[count.index].data
  type    = upper(sendgrid_domain_authentication.domain.dns[count.index].type)
  proxied = false
}

# Manually verify the domain via curl because the Terraform module doesn't support this yet.
resource "null_resource" "auth-verification" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -s \
      -X POST 'https://api.sendgrid.com/v3/whitelabel/domains/${sendgrid_domain_authentication.domain.id}/validate' \
      --header 'Authorization: Bearer ${var.sendgrid_api_key}'
    EOT
  }

  depends_on = [cloudflare_record.domain]
}
