#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile.opam"; "dockerfile.opam-cmdliner"]
--
(* Generate OPAM base images with particular revisions of OCaml and OPAM.
   ISC License is at the end of the file. *)

open Dockerfile
open Dockerfile_opam

(* Build the OPAM distributions from the OCaml base *)
let generate output_dir =
  let add_comment ?compiler_version ?(ppa=`None) tag =
    comment "OPAM for %s with %s%s" tag
     (match compiler_version with
      | None -> "system OCaml compiler"
      | Some v -> "local switch of OCaml " ^ v)
     (match ppa with
      | `SUSE -> " and OpenSUSE PPA"
      | `None -> "")
  in
  let apt_opam ?compiler_version ?(ppa=`None) distro =
    let tag =
      match distro with
      |`Ubuntu `V14_04 -> "ubuntu-14.04"
      |`Ubuntu `V14_10 -> "ubuntu-14.10"
      |`Debian `Stable -> "debian-stable"
      |`Debian `Testing -> "debian-testing"
    in
    add_comment ?compiler_version ~ppa tag @@
    header "avsm/docker-ocaml-build" tag @@
    install_ext_plugin @@
    (match ppa with
     | `SUSE -> Apt.add_opensuse_repo distro @@ Apt.install_system_ocaml @@ install_opam_from_source () (* Apt.install_system_opam *)
     | `None -> install_opam_from_source ()) @@
    Linux.Apt.add_user ~sudo:true "opam" @@
    opam_init ?compiler_version ()
  in
  let yum_opam ?compiler_version ?(ppa=`None) distro =
    let add_to_path path = 
     run "echo export PATH=\"%s:$PATH\" >> /etc/profile.d/usrlocal.sh" path @@
     run "chmod a+x /etc/profile.d/usrlocal.sh" in
    let tag =
      match distro with 
      |`CentOS6 -> "centos-6"
      |`CentOS7 -> "centos-7"
    in
    add_comment ?compiler_version ~ppa tag @@
    header "avsm/docker-ocaml-build" tag @@
    Linux.Git.init () @@
    install_ext_plugin @@
    (match ppa with
     | `SUSE -> RPM.add_opensuse_repo distro @@ RPM.install_system_ocaml @@ install_opam_from_source ()
     | `None -> install_opam_from_source () @@ add_to_path "/usr/local/bin") @@
    run "sed -i.bak '/LC_TIME LC_ALL LANGUAGE/aDefaults    env_keep += \"OPAMYES OPAMJOBS OPAMVERBOSE\"' /etc/sudoers" @@
    Linux.RPM.add_user ~sudo:true "opam" @@
    opam_init ?compiler_version () @@
    run_as_opam "opam install -y depext"
  in
  generate_dockerfiles output_dir [
    "ubuntu-14.04-ocaml-4.01.0-system",   apt_opam (`Ubuntu `V14_04);
    "ubuntu-14.04-ocaml-4.01.0-local",    apt_opam ~compiler_version:"4.01.0" (`Ubuntu `V14_04);
    "ubuntu-14.04-ocaml-4.02.1-local",    apt_opam ~compiler_version:"4.02.1" (`Ubuntu `V14_04);
    "ubuntu-14.04-ocaml-4.02.1-system",   apt_opam ~ppa:`SUSE (`Ubuntu `V14_04);
    "debian-stable-ocaml-4.01.0-system",  apt_opam ~compiler_version:"4.01.0" (`Debian `Stable);
    "debian-testing-ocaml-4.01.0-system", apt_opam (`Debian `Testing);
    "debian-stable-ocaml-4.02.1-system",  apt_opam ~ppa:`SUSE ~compiler_version:"4.02.1" (`Debian `Stable);
    "debian-testing-ocaml-4.02.1-local",  apt_opam ~compiler_version:"4.02.1" (`Debian `Testing);
    "centos-6-ocaml-4.02.1-system",       yum_opam ~ppa:`SUSE `CentOS6;
    "centos-7-ocaml-4.02.1-system",       yum_opam ~ppa:`SUSE `CentOS7;
    "centos-7-ocaml-4.01.0-local",        yum_opam ~ppa:`SUSE ~compiler_version:"4.01.0" `CentOS7;
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
    ~default_dir:"docker-opam-build"
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
