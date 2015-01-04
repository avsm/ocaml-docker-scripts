.PHONY: all
all:
	./generate.ml

depend:
	opam install -y ocamlscript dockerfile

sync:
	git submodule foreach 'git add .'
	git submodule foreach 'git commit -m sync -a || true'
	git submodule foreach 'git push || true'

add-submodules:
	git submodule add git@github.com:avsm/docker-ocaml-build
	git submodule add git@github.com:avsm/docker-opam-build
	git submodule add git@github.com:avsm/docker-opam-core-build

diff:
	git diff
	git submodule foreach git diff
