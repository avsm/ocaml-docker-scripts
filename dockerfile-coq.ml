#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile.opam"; "dockerfile.opam-cmdliner"]
--
(* Generate base images for the Coq theorem prover.
   ISC License is at the end of the file. *)

open Dockerfile
open Dockerfile_opam

let generate output_dir =
  let coq tag =
    header "avsm/docker-opam-build" tag @@
    run_as_opam "opam repo add coq-stable https://github.com/coq/repo-stable.git" @@
    run_as_opam "env OPAMYES=1 OPAMJOBS=2 opam installext coq"
  in
  generate_dockerfiles output_dir [
    "ubuntu-14.04-ocaml-4.02.1", coq "ubuntu-14.04-ocaml-4.02.1";
    "debian-stable-ocaml-4.01.0", coq "debian-stable-ocaml-4.01.0";
    "centos-7-ocaml-4.02.1", coq "centos-7-ocaml-4.02.1";
  ]

let _ =
  Dockerfile_opam_cmdliner.cmd
    ~name:"dockerfile-coq"
    ~version:"1.0.0"
    ~summary:"the Coq theorem prover"
    ~manual:"installs the Coq theorem prover using the OPAM source manager,
             for various Linux distributions.  It depends on the base OCaml
             and OPAM containers that are generated via the
             $(b,opam-dockerfile-opam) command."
    ~default_dir:"docker-opam-coq-build"
    ~generate
  |> Dockerfile_opam_cmdliner.run

(*
 * Copyright (c) 2015 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)
