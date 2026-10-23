# Deployment Guide

How infrastructure changes reach production, how to watch and verify a
deployment, and what to do when one goes wrong. For how the system fits
together, see the [README](../README.md).

All infrastructure deploys through the **Terraform Deployment** GitHub Actions
workflow (`.github/workflows/terraform.yml`), which authenticates to AWS with
OIDC. Don't apply from a local machine except in the emergency case at the end
of this guide.

- [Prerequisites](#prerequisites)
- [How a deployment runs](#how-a-deployment-runs)
- [Deploying](#deploying)
- [Monitoring a run](#monitoring-a-run)
- [Verifying](#verifying)
- [OIDC setup](#oidc-setup)
- [Troubleshooting](#troubleshooting)
- [Rollback](#rollback)
- [Emergency local apply](#emergency-local-apply)

## Prerequisites

- GitHub CLI (`gh`), authenticated, with push access to the repository
- For local plans only: Terraform `>= 1.10` (CI uses 1.15.5) and AWS
  credentials with read access

## How a deployment runs

| Trigger | Plan | Apply |
|---|---|---|
| Push to `main` changing `**.tf` or the workflow file | yes | yes |
| Pull request to `main` | yes, posted as a PR comment and uploaded as the `tfplan` artifact | no |
| Manual run with `action=plan` (default) | yes | no |
| Manual run with `action=apply` | yes | yes |

Steps in the `terraform` job:

1. Check out the code, install Terraform 1.15.5, assume
   `GithubActionsOIDC-LawnSmartApp-Role` through OIDC
2. Show where the state file is and list state files in the bucket
3. Create the state bucket `lawnsmartapp-terraform-state` if it is missing
   (versioned, encrypted, public access blocked, standard tags)
4. `terraform fmt -check` (reported, not blocking), `terraform init` with
   `environments/prod/backend.conf`, `terraform validate`
5. `terraform plan -var-file=environments/prod/terraform.tfvars -out=tfplan`
   (`continue-on-error`)
6. On apply runs: `terraform apply tfplan`, print outputs, invalidate `/*` on
   the CloudFront distribution

Runs on the same ref cancel each other (`concurrency` with
`cancel-in-progress`). State is locked with an S3 lockfile
(`lawnsmartapp-com/terraform.tfstate.tflock`) during plan and apply.

## Deploying

**Normal path: push to `main`.**

```bash
terraform fmt -recursive
terraform validate
git commit -am "feat: describe the change"
git push origin main     # plan + apply
```

For a change you want reviewed first, open a pull request instead; the plan
appears as a comment and nothing is applied until it merges.

**Manual run** (for example, to re-apply without a code change):

```bash
gh workflow run "Terraform Deployment" --ref main -f action=apply   # plan + apply
gh workflow run "Terraform Deployment" --ref main                   # plan only
```

Or in the browser: **Actions → Terraform Deployment → Run workflow**, choose
the branch and the action.

## Monitoring a run

```bash
gh run list --workflow terraform.yml --limit 5
gh run watch <RUN_ID>                 # live progress
gh run view <RUN_ID> --log            # full log
gh run view <RUN_ID> --log-failed     # only failed steps
gh run list --workflow terraform.yml --status failure --limit 5
```

Because the plan step uses `continue-on-error`, a run can be green even when
the plan failed (the apply step then fails on the missing plan, or is
skipped). Confirm the result in the log:

```bash
gh run view <RUN_ID> --log | grep -E "Plan:|No changes|Apply complete"
```

Most runs take under a minute. Changes that touch the CloudFront distribution
or issue a new certificate take several minutes, and CloudFront then needs
some time to propagate to all edge locations.

## Verifying

```bash
# All hostnames answer over HTTPS
for h in lawnsmartapp.com www.lawnsmartapp.com app.lawnsmartapp.com; do
  curl -sI "https://$h" | head -1
done

# Security headers are present
curl -sI https://lawnsmartapp.com | grep -iE "content-security|strict-transport|x-frame"

# DNS
dig +short lawnsmartapp.com
dig +short www.lawnsmartapp.com CNAME

# Outputs (needs AWS credentials and an initialized backend)
terraform output
```

## OIDC setup

The OIDC provider, role and policy are managed by `scripts/bootstrap-oidc.sh`,
not Terraform. Run it to create them in a new account or to update their tags
or permissions; it is idempotent.

```bash
bash scripts/bootstrap-oidc.sh
```

When you change the role's permissions, change the policy in the script and
apply it in the same commit, so the script and the live policy never drift.
Background and the original migration runbook:
[oidc-bootstrap-migration.md](oidc-bootstrap-migration.md).

## Troubleshooting

**`Could not assume role with OIDC`**
- Check the role's trust policy allows `repo:jxman/aws-hosting-lawnsmartapp:*`
- Check the `token.actions.githubusercontent.com` provider exists
- Check the workflow still has `permissions: id-token: write`

**`Error acquiring the state lock`**
- Another plan or apply holds `lawnsmartapp-com/terraform.tfstate.tflock`;
  wait for it (a local plan while CI runs causes this)
- If a crashed run left a stale lock:
  ```bash
  aws s3 ls s3://lawnsmartapp-terraform-state/lawnsmartapp-com/
  terraform force-unlock <LOCK_ID>
  ```

**Plan shows unexpected changes (drift)**
- Something changed outside Terraform. Find out what before applying; for
  example, AWS myApplications added an `awsApplication` tag that Terraform
  would have removed until it was added to `common_tags`
- Bring the change into the code, or `terraform import` a resource created by
  hand

**CloudFront update fails because the distribution is still deploying**
- Wait for the previous change to finish (`aws cloudfront get-distribution --id E1MYY1CD3E7WBQ --query Distribution.Status`), then re-run

**DNS doesn't resolve or the certificate doesn't validate**
- Check the records in hosted zone `Z04860973DG1BJ5J1VVBE`
- Check the certificate status: `aws acm describe-certificate --certificate-arn <ARN> --query Certificate.Status`

**`BucketNotEmpty` when destroying**
- The buckets have `null_resource` cleanup steps; if one still fails, empty
  all object versions:
  ```bash
  aws s3 rm s3://BUCKET --recursive
  aws s3api delete-objects --bucket BUCKET --delete "$(aws s3api list-object-versions --bucket BUCKET --output json | jq '{Objects: [.Versions[]?, .DeleteMarkers[]? | {Key: .Key, VersionId: .VersionId}]}')"
  ```

## Rollback

1. **Revert and push** (preferred): `git revert <COMMIT>` then
   `git push origin main`. The push applies the previous configuration.
2. **Re-run an earlier successful run**: `gh run rerun <RUN_ID>`. A re-run
   uses that run's commit.
3. **Apply from a rollback branch**: push the known-good commit to a branch
   and run `gh workflow run "Terraform Deployment" --ref <BRANCH> -f action=apply`.

## Emergency local apply

Only when GitHub Actions is unavailable and production is broken. This
bypasses CI and needs AWS credentials with write access.

```bash
terraform init -backend-config=environments/prod/backend.conf -reconfigure
terraform plan -var-file=environments/prod/terraform.tfvars -out=tfplan
# review the plan carefully
terraform apply tfplan
```

Afterwards, make sure the code on `main` matches what you applied, and let the
next CI run confirm there is no drift.
