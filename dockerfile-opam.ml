#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile.opam"; "dockerfile.opam-cmdliner"]
--
(* Generate OPAM base images with particular revisions of OCaml and OPAM.
   ISC License is at the end of the file. *)

open Dockerfile
open Dockerfile_opam

let distros = [ (`Ubuntu `V14_04); (`Ubuntu `V15_10);
                (`Debian `Stable); (`Debian `Testing); (`Debian `Unstable);
                (`Fedora `V22); (`Fedora `V23);
                (`CentOS `V6); (`CentOS `V7);
                (`OracleLinux `V7);
                (`Alpine `V3_3) ]
let ocaml_versions = [ "4.01.0"; "4.02.3"; "4.03.0+trunk" ]
let opam_versions = [ "1.2.2" ]

(* The distro-supplied version of OCaml *)
let builtin_ocaml_of_distro = function
  |`Debian `Stable -> Some "4.01.0"
  |`Debian `Testing -> Some "4.02.3"
  |`Ubuntu `V14_04 -> Some "4.01.0"
  |`Ubuntu `V15_04 -> Some "4.01.0"
  |`Ubuntu `V15_10 -> Some "4.01.0"
  |`Alpine `V3_3 -> Some "4.02.3"
  |`Fedora `V22 -> Some "4.02.0"
  |`Fedora `V23 -> Some "4.02.2"
  |_ -> None

(* The Docker tag for this distro *) 
let tag_of_distro = function
  |`Ubuntu `V14_04 -> "ubuntu-14.04"
  |`Ubuntu `V15_04 -> "ubuntu-15.04"
  |`Ubuntu `V15_10 -> "ubuntu-15.10"
  |`Debian `Stable -> "debian-stable"
  |`Debian `Unstable -> "debian-stable"
  |`Debian `Testing -> "debian-testing"
  |`CentOS `V6 -> "centos-6"
  |`CentOS `V7 -> "centos-7"
  |`Fedora `V21 -> "fedora-21"
  |`Fedora `V22 -> "fedora-22"
  |`Fedora `V23 -> "fedora-23"
  |`OracleLinux `V7 -> "oraclelinux-7"
  |`Alpine `V3_3 -> "alpine-3.3"

(* Build the OPAM distributions from the OCaml base *)
let add_comment ?compiler_version tag =
  comment "OPAM for %s with %s" tag
  (match compiler_version with
      | None -> "system OCaml compiler"
      | Some v -> "local switch of OCaml " ^ v)

(* Apt based Dockerfile *)
let apt_opam ?compiler_version distro tag =
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml" tag @@
    Linux.Apt.install "aspcud" @@
    install_opam_from_source () @@
    Linux.Apt.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version () @@
    run_as_opam "opam install -y depext" @@
    onbuild (run "sudo apt-get update && sudo apt-get -y upgrade") @@
    entrypoint_exec ["opam";"config";"exec";"--"]

(* Yum RPM based Dockerfile *)
let yum_opam ?compiler_version distro tag =
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml" tag @@
    Linux.RPM.dev_packages ~extra:"which tar" () @@
    install_opam_from_source ~prefix:"/usr" () @@
    run "sed -i.bak '/LC_TIME LC_ALL LANGUAGE/aDefaults    env_keep += \"OPAMYES OPAMJOBS OPAMVERBOSE\"' /etc/sudoers" @@
    Linux.RPM.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version () @@
    run_as_opam "opam install -y depext" @@
    entrypoint_exec ["opam";"config";"exec";"--"]

(* Apk (alpine) Dockerfile *)
let apk_opam ?compiler_version tag =
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml" tag @@
    Linux.Apk.install "opam aspcud rsync" @@
    Linux.Apk.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version () @@
    run_as_opam "opam install -y depext" @@
    entrypoint_exec ["opam";"config";"exec";"--"]

(* Construct a Dockerfile for a distro/ocaml combo, using the
   system OCaml if possible, or a custom OPAM switch otherwise *)
let to_dockerfile distro ocaml_version tag =
  let compiler_version =
    match builtin_ocaml_of_distro distro with 
    | Some v when v = ocaml_version -> None (* use builtin *)
    | None | Some _ (* when v <> ocaml_version *) -> Some ocaml_version
  in
  match distro with
  | `Ubuntu _ | `Debian _ -> apt_opam ?compiler_version distro tag
  | `CentOS _ | `Fedora _ | `OracleLinux _ -> yum_opam ?compiler_version distro tag
  | `Alpine _ -> apk_opam ?compiler_version tag

(* Build up the matrix of Dockerfiles *)
let matrix =
  List.map (fun opam_version ->
    List.map (fun ocaml_version ->
      List.map (fun distro ->
        let tag = tag_of_distro distro in
        Printf.sprintf "%s_ocaml-%s" tag ocaml_version,
        to_dockerfile distro ocaml_version tag
      ) distros
    ) ocaml_versions
  ) opam_versions |> List.flatten |> List.flatten

(* Generate a git branch per Dockerfile combination *)
let generate output_dir =
  generate_dockerfiles_in_git_branches output_dir matrix

let _ =
  Dockerfile_opam_cmdliner.cmd
    ~name:"dockerfile-opam"
    ~version:"1.1.0"
    ~summary:"the OPAM source package manager"
    ~manual:"installs the OPAM source-based package manager and a combination
             of local compiler switches for various Linux distributions.  It
             depends on the base OCaml containers that are generated via the
             $(b,opam-dockerfile-ocaml) command."
    ~default_dir:"opam-dockerfiles"
    ~generate
  |> Dockerfile_opam_cmdliner.run

(*
 * Copyright (c) 2015-2016 Anil Madhavapeddy <anil@recoil.org>
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
