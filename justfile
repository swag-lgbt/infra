export VOLTA_FEATURE_PNPM := "1"

[private]
default:
	@just --choose

[macos]
install:
	@which brew >/dev/null 2>&1 || ( echo "You need to install homebrew: See https://brew.sh/" && exit 1 )
	brew update

	# You need `fzf` for `just --choose` apparently...
	which fzf >/dev/null 2>&1 || brew install fzf

	# Install `tenv` to manage tofu versions, and detect & install the appropriate version
	brew install tofuutils/tap/tenv
	tenv tofu detect
	just tofu init

	# Install `tflint` to lint our tofu, and initialize it.
	brew install tflint
	tflint --init

	# Install `tfupdate` to update terraform deps as necessary
	brew install minamijoyo/tfupdate/tfupdate

	# Install `op`, the 1password CLI, to authorize our various secrets
	brew install 1password-cli
	op signin

	# Install `volta` to manage Node & PNPM versions
	brew install volta

	# Install pnpm dependencies
	pnpm install

@tofu *ARGS:
	CF_ACCOUNT_ID="op://swagLGBT/Tofu - Cloudflare API Token/Account ID" \
	AWS_ENDPOINT_URL_S3="op://swagLGBT/Tofu - Cloudflare API Token/R2 Endpoint" \
	AWS_ACCESS_KEY_ID="op://swagLGBT/Tofu - Cloudflare API Token/R2 Access Key ID" \
	AWS_SECRET_ACCESS_KEY="op://swagLGBT/Tofu - Cloudflare API Token/R2 Secret Access Key" \
	OP_SERVICE_ACCOUNT_TOKEN="$(op read "op://swagLGBT/1password Service Account Auth Token/credential")" \
	op run -- tofu {{ ARGS }}

fmt: fmt-js fmt-tofu

fmt-js:
	pnpm prettier . --write

fmt-tofu:
	tofu fmt -recursive


lint: lint-tofu lint-js

alias tflint := lint-tofu
lint-tofu *ARGS:
	tflint --recursive --disable-rule=terraform_required_version {{ ARGS }}

lint-js:
	pnpm run eslint