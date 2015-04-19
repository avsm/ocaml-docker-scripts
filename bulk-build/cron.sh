#!/bin/sh -ex

JOBS=25
make clean
make -j ${JOBS} depend
repoid=`cat opam-repo-rev`
if [ -d archive/$repoid ]; then
  echo Already built this revision, skipping $repoid
  exit 0
fi
make -j ${JOBS} -f Makefile.bulk
./generate_html.ml -g
mkdir -p archive/$repoid
mv logs archive/$repoid/
cp index.html theme.css archive/$repoid/
./graph.sh archive/$repoid
./index.sh
