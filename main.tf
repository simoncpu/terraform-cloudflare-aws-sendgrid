resource "cloudflare_zone" "domain" {
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
  bucket = var.aws_s3_bucket_name
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
  rule_set_name = var.aws_s3_bucket_name
}

resource "aws_ses_receipt_rule" "main" {
  name          = "s3"
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
