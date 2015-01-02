.PHONY: all
all:
	./generate.ml

depend:
	opam install -y ocamlscript dockerfile
