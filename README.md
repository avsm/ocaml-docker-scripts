OCaml and OPAM Docker scripts
-----------------------------

This repository uses the [OCaml Dockerfile](https://avsm.github.io/ocaml-dockerfile)
library to generate a series of Dockerfiles for various combinations of
[OCaml](http://ocaml.org) and the [OPAM](https://opam.ocaml.org) package manager.
There are a set of small scripts that output all the combinations and are easy
to modify, extend or duplicate for your own use.

    opam install docker-scripts

The script will then be installed in:

    `opam config var bin`/ocaml-docker-scripts

They are all executed directly as a shell script by using the
[OCamlScript](http://mjambon.com/ocamlscript.html) engine.  The installed
scripts are:

- `dockerfile-ocaml`: installs base OCaml packages
- `dockerfile-opam`: installs OPAM and OCaml switches
- `dockerfile-archive`: builds an OPAM source package archive and HTTP server
- `dockerfile-core`: builds the Jane Street Core library suite
- `dockerfile-coq`: builds the Coq compiler and adds its OPAM remote
- `dockerfile-bulk`: constructs the OPAM bulk build scripts

## Docker Repostories

The generated Dockerfiles are split into a sequence of containers that build on
each other, making it easy to pick the ones you need for your own purposes.
The default behaviour is to output the files into independent Git repositories:

- [docker-ocaml-build](https://github.com/avsm/docker-ocaml-build) is the base
  OCaml compiler and Camlp4 added on top of various Linux distributions.
- [docker-opam-build](https://github.com/avsm/docker-opam-build) layers the
  OPAM package manager over this image, and initialises it.
  The [opam-installext](https://github.com/avsm/opam-installext) OPAM plugin is
  also globally installed, so external library dependencies can also be automatically
  installed in all of the OS variants with a single command (`opam installext ssl`).
- [docker-opam-core-build](https://github.com/avsm/docker-opam-core-build) then
  installs all the libraries needed by [Real World OCaml](https://realworldocaml.org)
  using the `docker-opam-build` base, such as [Core](https://github.com/janestreet/core),
  [Async](https://github.com/janestreet/async), Menhir
  and [Cohttp](https://github.com/mirage/ocaml-cohttp).

The separate Git trees are tracked as Git submodules from this repository, and the
`Makefile` has utility targets to run operations across all of them.
There are automated builds triggered from pushes to this repository from the
[Docker Hub](http://hub.docker.com):

- `docker pull avsm/docker-ocaml-build` *[(link)](registry.hub.docker.com/u/avsm/docker-ocaml-build)*
- `docker pull avsm/docker-opam-build` *[(link)](registry.hub.docker.com/u/avsm/docker-opam-build)*
- `docker pull avsm/docker-opam-core-build` *[(link)](registry.hub.docker.com/u/avsm/docker-opam-core-build)*

## Automated Builds

These images can also be used as the basis of regular automated health checks
across the OPAM repository by doing bulk builds.

### OPAM Package builds

The `bulk-build/` directory contains the scripts that trigger a bulk build
of the OPAM database across a cluster.  They work by generating a large
`Makefile` which runs and logs an individual package across different OCaml
versions and distributions (primarily Ubuntu, Debian, and CentOS).

### Mirage OS builds

The [is-mirage-broken](https://github.com/mirage/is-mirage-broken) repository
is an example of an external use of these images.  It builds and runs the
[MirageOS](http://openmirage.org) regularly across all the variations provided
here, and pushes the results upstream to a logging repository.

You can (and are encouraged) to get in touch if you make use of these Docker
images for similar regular testing of your own projects.  If you are willing
to triage the results, get in touch with [Anil Madhavapeddy](http://anil.recoil.org)
to add your library to the regular testing done via [Rackspace](http://rackspace.com)
virtual machines (kindly provided by them as part of their Open Source outreach
program).
