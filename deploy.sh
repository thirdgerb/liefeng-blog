#!/bin/sh

echo "=== shart push blog source ==="

CHANGED=$(git diff-index --name-only HEAD --)

if [ -z "$CHANGED" ]; then
    echo "no change, exit"
    exit;
fi
git add -A
git ci -m "update"
git push origin master:master

echo "=== start push blog html ==="

hugo
cd public
git add -A
git ci -m "update"
git push origin master:master
cd ..
