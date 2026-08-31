#!/usr/bin/env bash
# Build a throwaway git repo for one synthetic check-comments fixture.
#
#   setup.sh <fixture> <branch> <dest>
#
# main/ is committed on main, branch/ on top as the change under review, so
# `git diff $(git merge-base HEAD main)` shows exactly the planted comments.
set -euo pipefail

fixture=$1
branch=$2
dest=$3
here=$(cd "$(dirname "$0")" && pwd)

rm -rf "$dest"
mkdir -p "$dest"
cd "$dest"
git init -q -b main
git config user.email eval@example.com
git config user.name "eval fixture"

cat > go.mod <<EOF
module example.com/$fixture

go 1.22
EOF
cp "$here/$fixture/main/"* .
git add -A
git commit -qm "base: $fixture package"

git checkout -qb "$branch"
cp "$here/$fixture/branch/"* .
git add -A
git commit -qm "feat: document the $fixture package"

echo "$dest ($branch, base main)"
