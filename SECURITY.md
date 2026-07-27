# Security findings and remediation

This repo is a rebuild of a real production system. Before this rework, an audit
of the original private repos found the following issues. Each is fixed in this
codebase; the "before" column describes what existed in the original scripts,
not anything present here.

| # | Finding | Before | Now |
|---|---------|--------|-----|
| 1 | **Secrets committed to git** | `thermal-repo-setup.sh` hardcoded a real InfluxDB token, a real internal (Tailscale) IP, and a real SMTP password as literal shell variables. The token was rotated twice by editing the file and committing the new value - every old value remained recoverable from git history. | `edge/bootstrap/device-setup.sh` fetches all of these from AWS SSM Parameter Store (`SecureString`) at provisioning time, using an IAM identity scoped to `infra/modules/iam`'s read-only SSM policy. Nothing secret is ever written to this repo. |
| 2 | **Real PII/business data in "example" config** | `.env.example` in the app repo used a real personal email address as `INFLUX_ORG` and a real internal IP as `INFLUX_URL` - not placeholders. Real bank-employee email addresses were hardcoded as alert recipients in the setup script. | `edge/app/.env.example` and `server/.env.example` use only placeholder values. No client name, employee name, or real IP appears anywhere in this repo or its history (fresh `git init`, not a history rewrite of the originals). |
| 3 | **Static AWS credentials in CI** | The original GitHub Actions workflow authenticated to AWS using long-lived `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` stored as GitHub secrets. | `.github/workflows/release-ecr.yml` and `terraform.yml` use GitHub's OIDC provider to assume a short-lived, repo-scoped IAM role (`infra/modules/iam`'s `github_actions_ecr_push`). The one place a long-lived AWS credential remains is the Pi devices' read-only ECR-pull IAM user (`infra/modules/iam`'s `ecr_reader`) - Pi hardware can't do OIDC, so this is scoped to pull-only on a single repository and documented as needing periodic rotation. |
| 4 | **Overprivileged container** | `docker-compose.yml` ran the sensor app with `privileged: true` (full device/kernel access) in addition to explicit `/dev/i2c-1`/`/dev/gpiomem` device mounts - the explicit mounts alone are sufficient. | `edge/app/docker-compose.yml` drops `privileged: true` entirely; the container runs as a non-root user with only the two device mounts plus `group_add` for their host GIDs. |
| 5 | **Unscoped deploy script** | `dupdate.sh` ran `docker rm -f $(docker ps -aq)` and `docker rmi -f $(docker images -q)` - removing every container and image on the host, not just this app's, on a box that could be shared with other workloads. | `edge/app/dupdate.sh` uses `docker compose down` / `pull` / `up -d`, scoped to this project's compose file only. |
| 6 | **No IaC for the server side** | The EC2 instance, security group, and the Grafana/InfluxDB stack were configured manually - no reproducible definition existed anywhere. | `infra/` (Terraform) provisions the EC2 instance, VPC/security group (SSH and Grafana restricted to admin CIDRs, never `0.0.0.0/0`), IAM roles, and SSM parameters. `server/docker-compose.yml` plus Grafana provisioning YAML/JSON define the dashboard stack as code. |
| 7 | **No security scanning anywhere** | No SAST, container scanning, IaC scanning, or secret scanning ran on any change. | `.github/workflows/security-scan.yml` runs Trivy (filesystem + built image), Checkov (Terraform), Bandit (Python), ShellCheck (bash), and gitleaks on every PR, push to `main`, and weekly on a schedule. |
| 8 | **Dead/duplicate code** | Three abandoned script variants (`main2.py`, `main3.py`, `main4.py`) and an unused `requirements2.txt` sat in the app repo alongside the shipped `main.py`, with no indication of which was current. | Only `edge/app/src/main.py` is shipped. The DHT22 sensor variant is kept as a clearly-labeled, documented alternative under `edge/app/examples/`, not built into the image. |

## Reporting

This is a personal portfolio project; there is no live production deployment
tied to this repository. If you find a security issue in the code or IaC here,
open a GitHub issue.
