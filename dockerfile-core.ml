#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile.opam"; "dockerfile.opam-cmdliner"]
--
(* Generate base images for Jane Street Core.
   ISC License is at the end of the file. *)

open Dockerfile
open Dockerfile_opam
module DD = Dockerfile_distro

let libs =
  "async_ssl jenga cohttp cryptokit menhir core_bench yojson core_extended"

let generate odir =
  let matrix =
    DD.map ~org:"ocaml/opam"
      (fun ~distro ~ocaml_version base ->
        let dfile =
          base @@
          run_as_opam "opam depext %s" libs @@
          run_as_opam "opam install -j 2 -y -v %s" libs
        in
        let tag = (DD.opam_tag_of_distro distro ocaml_version) ^ "_core" in
        (tag, dfile))
  in
  Dockerfile_distro.generate_dockerfiles_in_git_branches odir matrix

let _ =
  Dockerfile_opam_cmdliner.cmd
    ~name:"dockerfile-core"
    ~version:"1.1.0"
    ~summary:"the Jane Street Core packages"
    ~manual:"installs the Jane Street Core OCaml packages, including
             Core, Async and the Jenga build system, for various Linux
             distributions. It depends on the base OCaml and OPAM containers
             that are generated via the $(b,opam-dockerfile-opam) command."
    ~default_dir:"core-dockerfiles"
    ~generate
  |> Dockerfile_opam_cmdliner.run

(*
 * Copyright (c) 2016 Anil Madhavapeddy <anil@recoil.org>
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
