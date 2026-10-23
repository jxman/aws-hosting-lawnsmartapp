# App Subdomain Migration: Phase 1 (app.lawnsmartapp.com)

> **Status: phase 1 completed 2026-05-13** in `2cb4aea` (subdomain) and
> `44a090e` (CSP). `app.lawnsmartapp.com` now serves the same app as `www`.
> This was the handover for that change and is kept for its considerations,
> smoke tests and rollback steps. Phases 2 and 3 are on the
> [README roadmap](../README.md#roadmap). The summary is in the
> [changelog](../CHANGELOG.md#app-subdomain-phase-1).
>
> The "Current" code snippets below show the configuration **before** phase 1.
> The targeted SAN approach was chosen over the wildcard certificate.

## Context

LawnSmart is being migrated so that:
- `app.lawnsmartapp.com` serves the React app (current S3 + CloudFront stack)
- `www.lawnsmartapp.com` will eventually serve a marketing landing page (future phase)

**Phase 1 is infrastructure only — zero user impact.** We are simply making `app.lawnsmartapp.com` resolve to the same app. `www` and the root domain are untouched.

Full migration plan is documented in the [LawnSmart](https://github.com/jxman/LawnSmart) app repo at
`docs/subdomain-migration-plan.md`.

---

## Infrastructure Before Phase 1

| Resource | Current State |
|----------|--------------|
| ACM Certificate | Covers `lawnsmartapp.com` + `www.lawnsmartapp.com` |
| CloudFront aliases | `lawnsmartapp.com`, `www.lawnsmartapp.com` |
| Route53 records | A alias for root, weighted CNAME for `www` |
| S3 | Primary (us-east-1) + failover (us-west-1) with CloudFront OAC |
| Deployments | **GitHub Actions only** — see CLAUDE.md |

Terraform modules:
- `modules/acm-certificate/` — ACM cert with DNS validation
- `modules/cloudfront/` — CloudFront distribution with origin group failover
- `modules/route53/` — Route53 A and CNAME records
- `modules/s3-website/` — Primary + failover S3 buckets

---

## Changes Required for Phase 1

Three files need editing. All changes are additive — nothing is removed or replaced.

---

### Change 1: `modules/acm-certificate/main.tf`

**What**: Add `app.lawnsmartapp.com` as a Subject Alternative Name on the cert.

**Current:**
```hcl
resource "aws_acm_certificate" "cert" {
  domain_name               = var.site_name
  subject_alternative_names = ["www.${var.site_name}"]
  ...
}
```

**Change to:**
```hcl
resource "aws_acm_certificate" "cert" {
  domain_name               = var.site_name
  subject_alternative_names = ["www.${var.site_name}", "app.${var.site_name}"]
  ...
}
```

**Alternative — wildcard cert (preferred for long-term):**
If additional subdomains are anticipated (staging, landing page, etc.), a wildcard is cleaner.
A wildcard `*.lawnsmartapp.com` covers all subdomains but NOT the apex domain, so both are needed:
```hcl
resource "aws_acm_certificate" "cert" {
  domain_name               = var.site_name
  subject_alternative_names = ["*.${var.site_name}"]
  ...
}
```
This one change covers `www`, `app`, `staging`, and any future subdomain permanently.

**Important**: The cert has `create_before_destroy = true`. Terraform will issue a new cert,
DNS-validate it (automatic — same base domain, Route53 handles it), update CloudFront to use
the new ARN, then destroy the old cert. This is safe and causes no downtime.

---

### Change 2: `modules/cloudfront/main.tf`

**What**: Add `app.lawnsmartapp.com` to the CloudFront distribution's alias list.

**Current:**
```hcl
aliases = ["www.${var.site_name}", var.site_name]
```

**Change to:**
```hcl
aliases = ["www.${var.site_name}", var.site_name, "app.${var.site_name}"]
```

**Note**: This is an in-place update on the existing distribution — no downtime, no DNS changes
required by itself. CloudFront will simply start accepting requests for the new alias once the
cert covers it.

---

### Change 3: `modules/route53/main.tf`

**What**: Add a new A alias record for `app.lawnsmartapp.com` pointing to the same CloudFront distribution.

**Add after the existing `aws_route53_record.root_site` resource:**
```hcl
resource "aws_route53_record" "app_site" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "app.${var.site_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
```

**Note**: This is purely additive — does not touch the existing root or `www` records.

---

## Deployment Instructions

**CRITICAL: Do NOT deploy locally. All deployments go through GitHub Actions.**

### Step 1 — Format and validate locally
```bash
terraform fmt -recursive
terraform validate
```
Fix any errors before committing.

### Step 2 — Commit and push
```bash
git add modules/acm-certificate/main.tf modules/cloudfront/main.tf modules/route53/main.tf
git commit -m "Add app.lawnsmartapp.com subdomain — Phase 1 of www→landing page migration"
git push origin main
```

### Step 3 — Let the push deploy
The push to `main` runs plan and apply. A manual run is only needed to re-apply:
```bash
gh workflow run "Terraform Deployment" --ref main -f action=apply
```

### Step 4 — Monitor
```bash
gh run list --limit 5
gh run view [RUN_ID]
```

**Expected duration**: 10–15 minutes (ACM cert validation is the slowest step, up to 5 min).

---

## Smoke Test Checklist

Run these after the GitHub Actions workflow completes successfully:

- [ ] `https://app.lawnsmartapp.com` loads the LawnSmart React app
- [ ] No browser console errors (especially CSP violations)
- [ ] `https://www.lawnsmartapp.com` still works identically (no regression)
- [ ] `https://lawnsmartapp.com` still works (redirects to www or loads app)
- [ ] PWA manifest loads: Chrome DevTools → Application → Manifest — no errors
- [ ] Service worker registers under the new origin: DevTools → Application → Service Workers
- [ ] Google Analytics fires: check GA4 Realtime view while on `app.lawnsmartapp.com`
- [ ] Certificate covers new domain: click padlock in browser → certificate → SANs list

---

## Known Considerations

### HSTS include_subdomains
The existing CloudFront response headers policy sets:
```hcl
strict_transport_security {
  include_subdomains = true
}
```
This means browsers that have visited `www.lawnsmartapp.com` will **already enforce HTTPS**
on `app.lawnsmartapp.com` via HSTS preload. This is fine — our CloudFront serves HTTPS — but
it means the subdomain must have a valid cert before any browser that has visited `www` will
even attempt an HTTP fallback. The cert change in Step 1 handles this.

### CSP policy
The CloudFront CSP (`modules/cloudfront/main.tf`) uses `default-src 'self'`. Since the React
app at `app.lawnsmartapp.com` loads Google Fonts, Google Analytics, and Amazon product images,
verify the CSP includes:
- `style-src`: `https://fonts.googleapis.com`
- `font-src`: `https://fonts.gstatic.com`
- `img-src`: `https://m.media-amazon.com`
- `connect-src`: `https://www.google-analytics.com https://analytics.google.com`

Cross-reference the current CSP in `modules/cloudfront/main.tf` against the app's actual
external dependencies before confirming Phase 1 is complete. These entries may already be
present but are worth verifying.

### No localStorage impact
Phase 1 makes no changes to the app code. User data under `www.lawnsmartapp.com` is unaffected.
The `app.lawnsmartapp.com` origin starts with empty localStorage — expected, since no users
have data there yet.

### Rollback
Phase 1 is fully reversible:
1. Revert the three file changes
2. Push + trigger GitHub Actions
3. Remove the `app` Route53 record if desired (or leave it — it harmlessly points to nothing once CloudFront alias is removed)

---

## What Comes Next (Phase 2)

After verifying Phase 1, the next session will implement the in-app migration prompt on `www`.
This involves changes to the **LawnSmart React app** (not this Terraform repo):

- Add a migration banner to the React app served at `www.lawnsmartapp.com`
- Implement the hidden iframe + postMessage flow to transfer localStorage to `app.lawnsmartapp.com`
- Add export/import JSON fallback in Settings → Data tab

Reference: `docs/subdomain-migration-plan.md` Phase 2 section in the LawnSmart app repo.
