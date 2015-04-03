#!/bin/sh

if [ ! -d opam-repository ]; then
  git clone git://github.com/ocaml/opam-repository
fi

cd opam-repository
git pull || true
cd ..

ls archive | grep -v index.html | grep -v theme.css | ./generate_index.ml `pwd`/opam-repository
mv index.html archive/index.html
cp theme.css archive/theme.css
