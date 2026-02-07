#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

for dir in */; do
  dir="${dir%/}"
  [[ "$dir" == _* || "$dir" == .* ]] && continue
  echo "Stowing $dir ($(pwd)) -> ~"
  stow -R -t ~ "$dir"
done

if [[ -f _private/stow.sh ]]; then
  pushd _private > /dev/null
  ./stow.sh
  popd > /dev/null
fi
