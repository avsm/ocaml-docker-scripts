#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile.opam"; "dockerfile.opam-cmdliner"]
--
(* Generate local Dockerfiles for bulk builds.  These are intended to be
   rebuilt regularly so that the ONBUILD triggers are hit and the repository
   git checkout is refreshed. ISC License is at the end of the file. *)

open Dockerfile
open Dockerfile_opam

let generate output_dir uri branch =
  let pull_req =
    match uri with
    | None -> empty
    | Some uri ->
        run_as_opam "cd /home/opam/opam-repository &&
                     git pull --commit --no-edit %s %s 2>&1" uri branch
  in
  let local_build tag =
    header "avsm/docker-opam-build" tag @@
    Linux.Git.init () @@
    pull_req
  in
  generate_dockerfiles output_dir [
    "local-ubuntu-14.04-ocaml-4.01.0", local_build "ubuntu-14.04-ocaml-4.01.0";
    "local-ubuntu-14.04-ocaml-4.02.1", local_build "ubuntu-14.04-ocaml-4.02.1";
    "local-debian-stable-ocaml-4.01.0", local_build "debian-stable-ocaml-4.01.0";
    "local-debian-stable-ocaml-4.02.1", local_build "debian-stable-ocaml-4.02.1";
    "local-centos-7-ocaml-4.02.1", local_build "centos-7-ocaml-4.02.1";
  ]

open Cmdliner 

let uri =
  let doc = "Git URL of the remote OPAM repository pull request.
             If absent, the main OPAM repository master is used for the build" in
  Cmdliner.Arg.(value & opt (some string) None & info ["p";"pull"] ~docv:"GIT_URI" ~doc) 

let branch =
  let doc = "Remote branch for the OPAM repository pull request" in
  Cmdliner.Arg.(value & opt string "master" & info ["b";"branch"] ~docv:"BRANCH" ~doc) 

let _ =
  Dockerfile_opam_cmdliner.cmd
    ~name:"dockerfile-bulk"
    ~version:"1.0.0"
    ~summary:"OPAM automated bulk build scripts"
    ~manual:"installs the Dockerfiles for OPAM bulk builds. These are intended
             to be rebuilt regularly into fresh images so that the $(i,ONBUILD)
             triggers are hit and the repository git checkout is refreshed."
    ~default_dir:"docker-opam-bulk-build"
    ~generate
  |> fun (term, cmd) ->
  let term = Term.(term $ uri $ branch) in
  Dockerfile_opam_cmdliner.run (term, cmd)

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
