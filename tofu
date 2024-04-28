#!/usr/bin/env bash

set -euo pipefail

OP_TOKEN_ITEM="op://swagLGBT/1password Service Account Auth Token/credential"
TF_VAR_onepassword_service_account_token="$(op read "${OP_TOKEN_ITEM}")" tofu "$@"
