#!/usr/bin/env ocamlscript
Ocaml.packs := ["unix"; "str"; "cow"; "cow.syntax"]
--

let targets =
     Sys.readdir "logs"
  |> Array.map (fun b -> Str.string_after b 6)
  |> Array.map (Str.(split (regexp_string "-ocaml-")))
  |> Array.fold_left (fun a -> function [x;y] -> (x,y)::a |_ -> a) []

let all_packages =
     Sys.readdir "logs"
  |> Array.to_list
  |> List.map (fun d -> Sys.readdir (Printf.sprintf "logs/%s/raw/" d))
  |> List.map Array.to_list
  |> List.flatten
  |> List.fold_left (fun a b -> if List.mem b a then a else b::a) []
  |> List.sort compare

(* Some helper functions *)
let gen_hashtbl fn =
  let h = Hashtbl.create 1 in
  List.iter (fn h) targets;
  h

let keys h =
  Hashtbl.fold (fun k v a -> if List.mem k a then a else k::a) h []

let rec repeat n x =
  match n with
  | 1 -> x
  | n -> (repeat (n-1) x) @ x

(* List of operating system and OCaml version variants *)
let os_hash = gen_hashtbl (fun h (os,ver) -> Hashtbl.add h os ver)
let versions_hash = gen_hashtbl (fun h (os,ver) -> Hashtbl.add h ver os)
let versions = keys versions_hash
let num_versions = List.length versions
let os = keys os_hash
let num_os = List.length os

(* Package database *)
let dir ty os ver pkg = Printf.sprintf "logs/local-%s-ocaml-%s/%s/%s" os ver ty pkg
let is_ok os ver pkg = Sys.file_exists (dir "ok" os ver pkg)
let is_err os ver pkg = Sys.file_exists (dir "err" os ver pkg)

(** HTML output functions *)
let html ~title body =
  <:html<<html><head><meta charset="UTF-8" /><title>$str:title$</title></head><body>$body$</body></html>&>>

let cell_ok os ver pkg = <:html<<td><a href=$str:dir "raw" os ver pkg$>✔</a></td>&>>
let cell_err os ver pkg = <:html<<td><a href=$str:dir "raw" os ver pkg$>✘</a></td>&>>
let cell_unknown os ver pkg = <:html<<td>☐</td>&>>

let pkg_ents pkg =
  List.flatten (
    List.map (fun os ->
      List.map (fun ver ->
        if is_ok os ver pkg then cell_ok os ver pkg
        else if is_err os ver pkg then cell_err os ver pkg
        else cell_unknown os ver pkg
      ) versions
    ) os
  )

let results =
   let os_headers = List.map (fun os -> <:html<<th colspan=$int:num_versions$>$str:os$</th>&>>) os in
   let version_headers = List.map (fun v -> <:html<<th>$str:v$</th>&>>) versions in
   let pkg_row pkg = <:html<<tr><td><b>$str:pkg$</b></td>$list:pkg_ents pkg$</tr>&>> in
   <:html<
      <table border="1">
        <tr><th>Package</th>$list:os_headers$</tr>
        <tr><th></th>$list:repeat num_os version_headers$</tr>
        $list:List.map pkg_row all_packages$
      </table>
   >>

let _ =
  html ~title:"Test Results" results
  |> Cow.Html.to_string
  |> print_endline

