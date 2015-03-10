#!/bin/sh -ex

ver=$1
cd $ver
find . -name \*.buildtime | xargs cat > build-times.txt
gnuplot ../../build-times.gp
