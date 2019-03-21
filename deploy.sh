#!/bin/sh

if [ -z $1 ]; then
    echo "error: need message"
    exit 1;
fi

echo "=== shart push blog source ==="

CHANGED=$(git diff-index --name-only HEAD --)

if [ -z "$CHANGED" ]; then
    echo "no change, exit"
    exit 1;
fi
git add -A
git ci -m "update : $1"
git push origin master:master

echo "=== start push blog html ==="

hugo
cd public
git add -A
git ci -m "update : $1"
git push origin master:master
cd ..
