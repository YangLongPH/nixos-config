#!/usr/bin/env bash
# List tags of an image on a Harbor registry
# Usage: harbor-tags <repo> [project] [domain]
# Defaults: project=goline, domain=docker2.goline.vn
# Credentials: read from ~/.docker/config.json
#
# Examples:
#   harbor-tags inapt
#   harbor-tags inapt goline docker2.goline.vn
#   harbor-tags kafka-ui kms docker2.goline.vn

REPO=${1:?Usage: harbor-tags <repo> [project] [domain]}
PROJECT=${2:-goline}
DOMAIN=${3:-docker2.goline.vn}

CREDS=$(python3 -c "
import json, base64, sys
cfg = json.load(open('$HOME/.docker/config.json'))
auth = cfg.get('auths', {}).get('$DOMAIN', {}).get('auth', '')
print(base64.b64decode(auth).decode() if auth else ':')
" 2>/dev/null)

curl -s -u "$CREDS" \
  "https://${DOMAIN}/api/v2.0/projects/${PROJECT}/repositories/${REPO}/artifacts?page_size=100" \
  | jq -r '.[].tags[]?.name'
