#!/bin/sh -ex

ver=$1
cd archive/$ver
find . -name \*.buildtime | xargs cat > build-times.txt
gnuplot ../../build-times.gp
