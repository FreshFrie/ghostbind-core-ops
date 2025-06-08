#!/usr/bin/env bash
set -euo pipefail
REPO="${1:-$(git remote get-url origin | sed -E 's#.*/([^/]+/[^/.]+)(\.git)?$#\1#')}"
KEY_NAME="ci_deploy_key"
if [[ ! -f $KEY_NAME ]]; then
  echo "🔑  Generating CI deploy key …"
  ssh-keygen -t ed25519 -C "ghostbind-ci" -f "$KEY_NAME" -N ""
fi
echo "🔐  Pushing private key into GitHub secret CI_DEPLOY_KEY …"
cat "$KEY_NAME" | gh secret set CI_DEPLOY_KEY --repo "$REPO" --body -
echo "📋  IMPORTANT: paste the public key below into *Settings → Deploy Keys* (Write)."
cat "$KEY_NAME.pub"
echo "✅  Done.  Next: run ‘make safe’ or the full ‘make all’."
