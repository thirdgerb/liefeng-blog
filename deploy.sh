#!/bin/sh

if [ -z "$1" ]; then
    echo "error: need message"
    exit 1;
fi

echo "=== shart push blog source ==="

CHANGED=$(git diff-index --name-only HEAD --)

if [ -z "$CHANGED" ]; then
    echo "no change"
else
    git add -A
    git ci -m "update : $1"
    git push origin master:master
fi

echo "=== start push blog html ==="

hugo
cd public
CHANGED=$(git diff-index --name-only HEAD --)
if [ -n "$CHANGED" ]; then
    git add -A
    git ci -m "update : $1"
    git push origin master:master
fi
cd ..
