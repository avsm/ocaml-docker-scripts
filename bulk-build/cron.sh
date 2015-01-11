#!/bin/sh -ex

JOBS=15
make clean
make -j ${JOBS} depend
make -j ${JOBS} -f Makefile.bulk
./generate.ml -g
