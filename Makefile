.PHONY: all
all:
	./generate.ml

depend:
	opam install -y ocamlscript dockerfile

submodules:
	git submodule add git@gitbhub.com:avsm/docker-ocaml-build
	git submodule add git@gitbhub.com:avsm/docker-opam-build
	git submodule add git@gitbhub.com:avsm/docker-opam-core-build
