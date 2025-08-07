#!/usr/bin/env bash
set -o errexit

# 1. Install dependencies
mix deps.get --only prod

# 2. Compile
MIX_ENV=prod mix compile

# 3. Compile assets (tailwind, esbuild)
mix assets.deploy

# 4. Generate digests
mix phx.digest
