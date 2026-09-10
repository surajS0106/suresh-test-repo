# EC2 Instance

A single EC2 instance in its own VPC, on a public subnet, behind a security
group — the smallest useful starting point for a Linux workload on AWS.

```
              Internet
                 │
         ┌───────▼────────┐
         │      IGW       │
         └───────┬────────┘
                 │
   public subnet │  10.0.1.0/24
         ┌───────▼────────┐
         │  EC2 instance  │  t3.micro, encrypted gp3 root
         │  + SG + SSM    │
         └────────────────┘
```

## What it creates

- **VPC** (`vpc.tf`) with DNS support, one public subnet in the first available
  AZ, an internet gateway and a route table.
- **Instance** (`ec2_instance.tf`) running the latest Amazon Linux 2023, resolved
  via a `data "aws_ami"` lookup so changing region needs no other edit.
- **Security group** allowing inbound on `var.app_port` from
  `var.ingress_cidr`, and unrestricted egress.
- **Instance profile** with `AmazonSSMManagedInstanceCore`.

## Security posture

- **No SSH.** There is no key pair and no port 22 rule. Shell access is via
  Session Manager, which needs no inbound rule at all and logs every session to
  CloudTrail:
  ```bash
  aws ssm start-session --target <instance-id>
  ```
- **IMDSv2 required** (`http_tokens = "required"`), which closes the
  SSRF-to-credential-theft path IMDSv1 leaves open.
- **Encrypted root volume** (gp3, `encrypted = true`).
- `var.ingress_cidr` defaults to `0.0.0.0/0` so the template works out of the
  box. **Narrow it.**

## Getting started

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # then edit
terraform init
terraform validate
terraform plan
terraform apply
```

`terraform validate` needs no AWS credentials, so run it first.

## Before production

| Setting | Change to | Why |
|---|---|---|
| `ingress_cidr` | your own range | The default is the entire internet |
| `assign_public_ip` | `false` | Put a load balancer in front instead |
| Remote state | Uncomment `backend "s3"` in `providers.tf` | Team-safe state with locking |
| TLS | Terminate HTTPS at a load balancer or on the instance | Port 80 alone is not enough |

A single instance is a single point of failure. Once you need availability, this
template's natural next step is an Auto Scaling group behind a load
balancer — see the **3-Tier App on AWS** template.

## Notes

- `user_data` installs nginx as a placeholder so the port answers on a fresh
  apply. Replace it with your real bootstrap.
- `user_data_replace_on_change` is `false`, so editing `user_data` will **not**
  rebuild the instance. Set it to `true` if you want changes to take effect
  automatically.
- The subnet lands in `data.aws_availability_zones.available.names[0]`. Pin
  `availability_zone` explicitly if you need a specific one.

## Cost

Roughly, in `us-east-1` at defaults: one `t3.micro` (~$8/mo, or free under the
AWS free tier) plus a 20 GiB gp3 volume (~$1.60/mo). The VPC, subnet, internet
gateway and security group are free. There is no NAT gateway, which is what keeps
this template cheap.
