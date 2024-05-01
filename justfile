default:
  just --list

@tofu *ARGS:
  CF_ACCOUNT_ID="op://swagLGBT/Tofu - Cloudflare API Token/Account ID" \
  AWS_ENDPOINT_URL_S3="op://swagLGBT/Tofu - Cloudflare API Token/R2 Endpoint" \
  AWS_ACCESS_KEY_ID="op://swagLGBT/Tofu - Cloudflare API Token/R2 Access Key ID" \
  AWS_SECRET_ACCESS_KEY="op://swagLGBT/Tofu - Cloudflare API Token/R2 Secret Access Key" \
  OP_SERVICE_ACCOUNT_TOKEN="$(op read "op://swagLGBT/1password Service Account Auth Token/credential")" \
  op run -- tofu {{ ARGS }}

lint:
  tflint