.PHONY: all depend sync add-submodules diff clean

all:
	./opam-dockerfile-ocaml.ml
	./opam-dockerfile-opam.ml
	./opam-dockerfile-core.ml
	./opam-dockerfile-archive.ml
	./opam-dockerfile-coq.ml
	./opam-dockerfile-bulk.ml

depend:
	opam install -y ocamlscript dockerfile

sync:
	git submodule foreach 'git add .'
	git submodule foreach 'git commit -m sync -a || true'
	git submodule foreach 'git push || true'
	git commit -a -m 'sync submodules' || true

add-submodules:
	git submodule add git@github.com:avsm/docker-ocaml-build
	git submodule add git@github.com:avsm/docker-opam-build
	git submodule add git@github.com:avsm/docker-opam-core-build
	git submodule add git@github.com:avsm/docker-opam-archive
	git submodule add git@github.com:avsm/docker-opam-coq-build

diff:
	git diff
	git submodule foreach git diff

clean:
	rm -f *.ml.exe
