#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile.opam"; "dockerfile.opam-cmdliner"]
--
(* Generate OPAM base images with particular revisions of OCaml and OPAM.
   ISC License is at the end of the file. *)

open Dockerfile
open Dockerfile_opam

(* Build the OPAM distributions from the OCaml base *)
let generate output_dir =
  let add_comment ?compiler_version tag =
    comment "OPAM for %s with %s" tag
     (match compiler_version with
      | None -> "system OCaml compiler"
      | Some v -> "local switch of OCaml " ^ v)
  in
  let apt_opam ?compiler_version distro =
    let tag =
      match distro with
      |`Ubuntu `V14_04 -> "ubuntu-14.04"
      |`Ubuntu `V15_04 -> "ubuntu-15.04"
      |`Ubuntu `V15_10 -> "ubuntu-15.10"
      |`Debian `Stable -> "debian-stable"
      |`Debian `Unstable -> "debian-stable"
      |`Debian `Testing -> "debian-testing"
    in
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml" tag @@
    Linux.Apt.install "aspcud" @@
    install_opam_from_source () @@
    Linux.Apt.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version () @@
    run_as_opam "opam install -y depext" @@
    onbuild (run "sudo apt-get update && sudo apt-get -y upgrade") @@
    entrypoint "[%S,%S,%S]" "opam" "config" "exec"
  in
  let yum_opam ?compiler_version distro =
    let tag =
      match distro with 
      |`CentOS6 -> "centos-6"
      |`CentOS7 -> "centos-7"
      |`Fedora_21 -> "fedora-21"
      |`Fedora_22 -> "fedora-22"
      |`Fedora_23 -> "fedora-23"
      |`Oracle_Linux_7 -> "oraclelinux-7"
    in
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml-dockerfiles" tag @@
    RPM.install_base_packages @@
    Linux.RPM.install "tar" @@
    install_opam_from_source ~prefix:"/usr" () @@
    run "sed -i.bak '/LC_TIME LC_ALL LANGUAGE/aDefaults    env_keep += \"OPAMYES OPAMJOBS OPAMVERBOSE\"' /etc/sudoers" @@
    Linux.RPM.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version () @@
    run_as_opam "opam install -y depext"
  in
  let apk_opam ?compiler_version () =
    add_comment ?compiler_version "alpine" @@
    header "ocaml/ocaml" "3.3"  (* TODO finish *)
  in
  generate_dockerfiles_in_git_branches output_dir [
    "ubuntu-14.04_ocaml-4.01.0",   apt_opam ~compiler_version:"4.01.0" (`Ubuntu `V14_04);
    "ubuntu-14.04_ocaml-4.02.3",   apt_opam ~compiler_version:"4.02.1" (`Ubuntu `V14_04);
    "ubuntu-14.04_ocaml-4.03.0dev",apt_opam ~compiler_version:"4.03.0+trunk" (`Ubuntu `V14_04);
    "ubuntu-15.10_ocaml-4.02.3",   apt_opam ~compiler_version:"4.02.3" (`Ubuntu `V15_10);
    "ubuntu-15.10_ocaml-4.02.3",   apt_opam ~compiler_version:"4.02.3" (`Ubuntu `V15_10);
    "ubuntu-15.10_ocaml-4.03.0dev",apt_opam ~compiler_version:"4.03.0+trunk" (`Ubuntu `V15_10);
    "debian-stable_ocaml-4.01.0",  apt_opam (`Debian `Stable);
    "debian-stable_ocaml-4.02.3",  apt_opam  ~compiler_version:"4.02.3" (`Debian `Stable);
    "debian-testing_ocaml-4.01.0", apt_opam ~compiler_version:"4.01.0" (`Debian `Testing);
    "debian-testing_ocaml-4.02.3", apt_opam ~compiler_version:"4.02.3" (`Debian `Testing);
    "debian-unstable_ocaml-4.01.0", apt_opam ~compiler_version:"4.01.0" (`Debian `Testing);
    "debian-unstable_ocaml-4.02.3", apt_opam ~compiler_version:"4.02.3" (`Debian `Testing);
    "debian-unstable_ocaml-4.03.0dev", apt_opam ~compiler_version:"4.03.0+trunk" (`Debian `Unstable);
    "centos-6_ocaml-4.02.3",       yum_opam ~compiler_version:"4.02.3" `CentOS6;
    "centos-7_ocaml-4.02.3",       yum_opam ~compiler_version:"4.02.3" `CentOS7;
    "centos-7_ocaml-4.01.0",       yum_opam ~compiler_version:"4.01.0" `CentOS7;
    "centos-7_ocaml-4.01.0",       yum_opam ~compiler_version:"4.01.0" `CentOS7;
    "oraclelinux-7_ocaml-4.02.3",  yum_opam ~compiler_version:"4.02.3" `Oracle_Linux_7;
  ]

let _ =
  Dockerfile_opam_cmdliner.cmd
    ~name:"dockerfile-opam"
    ~version:"1.0.0"
    ~summary:"the OPAM source package manager"
    ~manual:"installs the OPAM source-based package manager and a combination
             of local compiler switches for various Linux distributions.  It
             depends on the base OCaml containers that are generated via the
             $(b,opam-dockerfile-ocaml) command."
    ~default_dir:"opam-dockerfiles"
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
