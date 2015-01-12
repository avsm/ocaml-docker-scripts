#!/bin/sh -ex

JOBS=15
make clean
make -j ${JOBS} depend
make -j ${JOBS} -f Makefile.bulk
./generate_html.ml -g
repoid=`cat opam-repo-rev`
mkdir -p archive/$repoid
mv logs archive/$repoid/
cp index.html theme.css archive/$repoid/
