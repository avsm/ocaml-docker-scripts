#!/usr/bin/env ocamlscript
Ocaml.packs := ["unix"; "dockerfile"]
--
open Dockerfile
open Printf

let header (img,tag) = [
  from ~tag img;
  maintainer "Anil Madhavapeddy <anil@recoil.org>";
]

(** Debian rules *)
module Apt = struct
  let apt_update =
    run "apt-get -y update"

  let base_packages = [
    run "apt-get -y install sudo pkg-config git build-essential m4 software-properties-common aspcud unzip curl libx11-dev";
    run "git config --global user.email %S" "docker@example.com";
    run "git config --global user.name %S" "Docker CI"
  ]
 
  let system_compiler = [
    run "apt-get -y install ocaml ocaml-native-compilers camlp4-extra"
  ]

  let ppa = function
  |`Ubuntu ->
      let url = "http://download.opensuse.org/repositories/home:/ocaml/xUbuntu_14.04" in
      let repo = sprintf "deb %s/ /" url in
      [ run "echo %S > /etc/apt/sources.list.d/opam.list" repo;
        run "curl -OL %s/Release.key" url;
        run "apt-key add - < Release.key";
        apt_update
      ]

  let build_opam_from_source = [
     run "git clone -b 1.2 git://github.com/ocaml/opam";
     run "sh -c \"cd opam && make cold && make install\""
  ]

  let opamhome = "/home/opam"

  let add_opam_user =
    let opamsudo = "opam ALL=(ALL:ALL) NOPASSWD:ALL" in
    let opamsudo_file = "/etc/sudoers.d/opam" in
    [
    run "adduser --disabled-password --gecos '' opam";
    run "passwd -l opam";
    run "echo %S > %s" opamsudo opamsudo_file;
    run "chmod 440 %s" opamsudo_file;
    run "chown root:root %s" opamsudo_file;
    run "chown -R opam:opam /home/opam";
    user "opam";
    env ["HOME", opamhome];
    env ["OPAMYES","1"];
    workdir "%s" opamhome;
    ]

  let run_as_opam =
    ksprintf (fun c -> run "sudo -u opam sh -c %S" c) 

  let opam_init
    ?(repo="git://github.com/ocaml/opam-repository") 
    ?(compiler_version="4.02.1") () =

    [ run_as_opam "git clone %s" repo;
      run_as_opam "opam init -a -y %s/opam-repository" opamhome;
      run_as_opam "opam switch -y %s" compiler_version;
      workdir "%s/opam-repository" opamhome;
      onbuild (run_as_opam "cd %s/opam-repository && git pull && opam update -u -y" opamhome)
    ]
    
end

let ubuntu_14_04 =
  let open Apt in
  header ("ubuntu","trusty") @
  base_packages @
  system_compiler @
  ppa `Ubuntu @
  build_opam_from_source @
  add_opam_user @
  opam_init ()

let _ = print_endline (string_of_file ubuntu_14_04)
