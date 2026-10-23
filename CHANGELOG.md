# Changelog

What has shipped, and the longer write-ups behind some of the design
decisions. The [README](./README.md) describes how the system works today;
this file records how it got there.

- [Shipped features and fixes](#shipped-features-and-fixes)
- [Design history](#design-history)

---

## Shipped features and fixes

Oldest first.

### Initial hosting stack (2025-06)

- Terraform modules for S3 website hosting, CloudFront, ACM and Route53 serving `lawnsmartapp.com`
- GitHub Actions workflow running `terraform plan`/`apply` against an S3 state backend
- Manual production deployment trigger (`workflow_dispatch`)
- Dev environment moved to the `dev.lawnsmartapp.com` subdomain

### OIDC and CI hardening (2025-07)

- Project-specific GitHub Actions OIDC role (`GithubActionsOIDC-LawnSmartApp-Role`) with a trust policy restricted to this repository, replacing long-lived AWS keys
- Workflow no longer reports a "failure" status for plans that complete successfully
- Route53 hosted zone lookup fixed for subdomain deployments
- `force_destroy` plus `null_resource` cleanup steps so `terraform destroy` can empty versioned buckets and detach the replication role
- Redesign for per-environment state isolation (`environments/{prod,dev,staging}/backend.conf`)
- Local deployment scripts (`deploy-prod.sh`, `deploy-dev.sh`, `deploy-staging.sh`, `deploy.sh`) deprecated and moved to `archived/local-deployment-scripts/`

### Production-only CI (2025-08)

- GitHub Actions fixed to the `prod` environment and its backend; dev and staging configs remain for manual use only

### Tagging standard and OIDC bootstrap (2025-11)

- All resources tagged with the 10 standard tags (`Environment`, `ManagedBy`, `Owner`, `Project`, `Service`, `GithubRepo`, `Site`, `BaseProject`, `Name`, `SubService`)
- OIDC provider, role and policy moved out of Terraform into `scripts/bootstrap-oidc.sh`; `modules/github-oidc/` archived. See [OIDC: Terraform module to bootstrap script](#oidc-terraform-module-to-bootstrap-script)
- `ManagedBy` corrected to `bootstrap-script` for the OIDC resources
- Explicit ACM tag-management permissions added to the OIDC policy
- LawnSmartApp application created in AWS myApplications, which tags member resources with `awsApplication`

### `app.lawnsmartapp.com` (2026-05)

- `app.lawnsmartapp.com` added as an ACM SAN, a CloudFront alias and a Route53 A alias, serving the same React app as `www`. See [App subdomain, phase 1](#app-subdomain-phase-1)
- Content-Security-Policy expanded for Google Fonts (`fonts.googleapis.com`, `fonts.gstatic.com`) and Amazon product images (`m.media-amazon.com`)

### S3 lockfile locking (2026-10)

- S3 backend switched from DynamoDB locking (`dynamodb_table`, deprecated by Terraform) to `use_lockfile = true`; `required_version` raised to `>= 1.10.0` and CI pinned to Terraform 1.15.5 ([#1](https://github.com/jxman/aws-hosting-lawnsmartapp/issues/1))
- Workflow no longer creates a DynamoDB lock table; `backend-configs/` (only used by the archived deploy script) removed
- GitHub Actions bumped to their Node 24 majors: checkout v7, setup-terraform v4, configure-aws-credentials v6, upload-artifact v7, github-script v9
- `awsApplication` tag brought under Terraform (`aws_application_arn`, prod only), so applies no longer strip the tag myApplications added
- Terraform state buckets tagged with the 10 standard tags; the workflow and `create-prerequisites.sh` now tag new state buckets, and `create-prerequisites.sh` creates `lawnsmartapp-*` buckets instead of names copied from synepho
- `website_url` output fixed: it read the empty `var.site_name` and printed `https://`; it now uses the computed site domain
- Documentation reorganized: README rewritten to the standard layout, this changelog added, and the deployment guide, OIDC runbook and app subdomain handover moved to `docs/`
- DynamoDB lock tables and their IAM permissions kept for about two weeks as a rollback path; removal tracked in [#2](https://github.com/jxman/aws-hosting-lawnsmartapp/issues/2)

---

## Design history

### OIDC: Terraform module to bootstrap script

_2025-11-16._ The OIDC provider, IAM role and IAM policy were originally
managed by `modules/github-oidc/`. That had two problems:

- The module used `lifecycle { ignore_changes = [tags] }`, so the resources'
  tags could never be brought up to the tagging standard.
- It was inconsistent with synepho-s3cf-site, which already managed OIDC with
  a bootstrap script.

The resources were removed from Terraform state with `terraform state rm`
(not deleted from AWS), and `scripts/bootstrap-oidc.sh` took over. The script
is idempotent: it creates the provider, policy and role if they are missing,
otherwise updates their tags and policy document. It also avoids a chicken and
egg problem: the role that runs Terraform is not managed by that same
Terraform.

The full runbook, including how to import the resources back into Terraform,
is in [docs/oidc-bootstrap-migration.md](docs/oidc-bootstrap-migration.md).

### App subdomain, phase 1

_2026-05-13._ LawnSmart is moving the React app to `app.lawnsmartapp.com` so
that `www.lawnsmartapp.com` can later serve a marketing landing page. Phase 1
was infrastructure only, with no user-facing change: `app` was added to the
certificate, the CloudFront aliases and Route53, pointing at the same
distribution and bucket as `www`.

Decisions and considerations:

- **Targeted SAN, not a wildcard.** The certificate lists `www` and `app`
  explicitly. A `*.lawnsmartapp.com` wildcard would cover future subdomains
  (still alongside the apex) and remains an option. The certificate uses
  `create_before_destroy`, so the change issued a new certificate and swapped
  CloudFront to it without downtime (the ARN changed from `08e59308-…` to
  `081bc4fc-…`).
- **HSTS already covers `app`.** The response headers policy sends
  `includeSubDomains; preload`, so browsers that have visited `www` refuse
  plain HTTP on `app`. The certificate had to cover `app` before the alias
  went live.
- **CSP.** The app loads Google Fonts, Google Analytics and Amazon product
  images, which the CSP was expanded to allow.
- **localStorage does not carry over.** Each origin has its own storage, so
  `app` starts empty. Moving users' data from `www` to `app` is phase 2 (see
  the [README roadmap](README.md#roadmap)).

The handover and smoke-test checklist are in
[docs/app-subdomain-migration.md](docs/app-subdomain-migration.md).
