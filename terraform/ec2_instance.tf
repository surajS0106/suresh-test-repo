/**
 * The instance, its security group, and an instance profile granting Session
 * Manager access — so there is no need for an SSH key or an open port 22.
 */

resource "aws_security_group" "web" {
  name_prefix = "${local.name_prefix}-web-"
  description = "Inbound web traffic to the instance"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-web-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from the allowed range"

  cidr_ipv4   = var.ingress_cidr
  ip_protocol = "tcp"
  from_port   = var.app_port
  to_port     = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "web_egress" {
  security_group_id = aws_security_group.web.id
  description       = "Outbound for patching and AWS APIs"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# ── Instance identity ────────────────────────────────────────────────────────

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name_prefix        = "${local.name_prefix}-ec2-"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-ec2-role" })
}

# Shell access via `aws ssm start-session` instead of SSH: no key pair to
# manage, no port 22 open, and every session is logged in CloudTrail.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name_prefix = "${local.name_prefix}-ec2-"
  role        = aws_iam_role.instance.name

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-ec2-profile" })
}

# ── Instance ─────────────────────────────────────────────────────────────────

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.instance.name
  associate_public_ip_address = var.assign_public_ip

  # IMDSv2 only — closes the SSRF-to-credential-theft path IMDSv1 allows.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = merge(local.common_tags, { Name = "${local.name_prefix}-root" })
  }

  monitoring = var.detailed_monitoring
  user_data  = var.user_data

  # Re-running user_data would need a replacement; keep that opt-in.
  user_data_replace_on_change = false

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-web" })
}
