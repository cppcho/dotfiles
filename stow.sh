#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

for dir in */; do
  dir="${dir%/}"
  [[ "$dir" == _* || "$dir" == .* ]] && continue
  echo "stow -R $dir"
  stow -R -t ~ "$dir"
done
