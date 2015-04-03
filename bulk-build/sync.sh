#!/bin/sh

rsync -avz archive/ opam@opam.ocaml.org:/logs/builds/
#rsync -avz archive/`cat opam-repo-rev`/ recoil.org:public_html/opam-bulk/
