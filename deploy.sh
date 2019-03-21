#!/bin/sh

echo "=== shart push blog source ==="

git push origin master:master

echo "=== start push blog html ==="

hugo
cd public
git add -A
git ci -m "update"
git push origin master:master
cd ..
