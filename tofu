#!/usr/bin/env bash

set -euo pipefail

# Give tofu a service account to read credentials
OP_AUTH_TOKEN="op://swagLGBT/1password Service Account Auth Token/credential"
TF_VAR_onepassword_service_account_token="$(op read "$OP_AUTH_TOKEN")"
export TF_VAR_onepassword_service_account_token

# Tell tofu how to talk to cloudflare r2
CF_ACCOUNT_ID="op://swagLGBT/Tofu - Cloudflare API Token/Account ID"
AWS_ENDPOINT_URL_S3="https://$(op read "$CF_ACCOUNT_ID").r2.cloudflarestorage.com"
AWS_ACCESS_KEY_ID="$(op read "op://swagLGBT/Tofu - Cloudflare API Token/R2 Access Key ID")"
AWS_SECRET_ACCESS_KEY="$(op read "op://swagLGBT/Tofu - Cloudflare API Token/R2 Secret Access Key")"

export AWS_ENDPOINT_URL_S3
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

tofu "$@"
