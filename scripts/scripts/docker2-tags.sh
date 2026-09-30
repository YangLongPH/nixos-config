#!/usr/bin/env bash
# List tags of an image on docker2.goline.vn
# Usage: docker2-tags <repo>   (e.g. docker2-tags inapt)
REPO=${1:?Usage: docker2-tags <repo>}
curl -s -u "goline:Goline@docker2" \
  "https://docker2.goline.vn/api/v2.0/projects/goline/repositories/${REPO}/artifacts?page_size=100" \
  | jq -r '.[].tags[]?.name'
