#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile.opam"; "dockerfile.opam-cmdliner"]
--
(* Generate an OPAM archive server that serves content via
   an HTTP server. ISC License is at the end of the file. *)

open Dockerfile
open Dockerfile_opam

let generate output_dir =
  let opam_archive =
    header "ocaml/ocaml" "ubuntu-15.10-ocaml-4.02.3" @@
    run_as_opam "cd /home/opam/opam-repository && git pull origin master" @@
    run_as_opam "opam update -u -y" @@
    run_as_opam "OPAMYES=1 OPAMJOBS=2 opam depext -u -i lwt ssl tls cohttp" @@
    run_as_opam "cd /home/opam/opam-repository && opam-admin make" @@
    onbuild (run_as_opam "cd /home/opam/opam-repository && git pull && opam-admin make")
  in
  generate_dockerfiles "docker-opam-archive" [ "opam-archive", opam_archive ]

let _ =
  Dockerfile_opam_cmdliner.cmd
    ~name:"dockerfile-archive"
    ~version:"1.1.0"
    ~summary:"the OPAM package archive"
    ~manual:"installs the OPAM package archive and an HTTP server using
             $(i,cohttp) to serve the contents.  This is useful when deployed
             as a linked Docker container for bulk builds.  It depends on
             the base OCaml and OPAM containers that are generated via the
             $(b,opam-dockerfile-opam) command."
    ~default_dir:"docker-opam-archive"
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
