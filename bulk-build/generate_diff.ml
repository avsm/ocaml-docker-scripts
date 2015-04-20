#!/usr/bin/env ocamlscript
Ocaml.packs := ["unix"; "str"; "cow"; "cow.syntax"; "cmdliner"; "core_kernel"] ;;
--

open Cmdliner

let read_file fname =
  let fin = open_in fname in
  let b = Buffer.create 128 in
  (try while true do
    Buffer.add_string b (input_line fin);
    Buffer.add_char b '\n'
  done;
  with End_of_file -> ());
  close_in fin;
  Buffer.contents b


open Core_kernel.Std
type res = Success | Failure

let make_res dir sub data init =
  try Array.fold (Sys.readdir (dir^"/"^sub)) ~init ~f:(fun a key -> String.Map.add a ~key ~data)
  with _ -> prerr_endline "Exn"; init

let gather_res dir =
  String.Map.empty |>
  make_res dir "err" Failure |>
  make_res dir "ok"  Success

type diff =
  | New_and_works
  | New_and_fails
  | Now_works
  | Now_fails
  | Gone
  
let diff d1 d2 =
  gather_res d1 |> fun r1 ->
  gather_res d2 |> fun r2 ->
  String.Map.merge r1 r2
    (fun ~key v ->
      match v with
      | `Both (Success, Failure) -> Some Now_fails
      | `Both (Failure, Success) -> Some Now_works
      | `Left Success | `Left Failure -> Some Gone
      | `Right Success -> Some New_and_works
      | `Right Failure -> Some New_and_fails
      | `Both (Success, Success) -> None
      | `Both (Failure, Failure) -> None
    )
  |> Map.to_alist

let _ =
  let d1 = Sys.argv.(1) in
  let d2 = Sys.argv.(2) in
  let os = "local-ubuntu-14.04-ocaml-4.02.1" in
  let dir = sprintf "archive/%s/logs/%s" in
  diff (dir d1 os) (dir d2 os) |>
  List.map ~f:(fun (pkg,res) ->
    let st =
      match res with
      | New_and_works -> <:html<$str:pkg$<span class="ok">&#9650;</span>&>>
      | New_and_fails -> <:html<$str:pkg$<span class="err">&#9660;</span>&>>
      | Now_works -> <:html<$str:pkg$<span class="ok2">&#9650;</span>&>>
      | Now_fails -> <:html<$str:pkg$<span class="err2">&#9660;</span>&>>
      | Gone -> <:html<<strike>$str:pkg$</strike>&>>
    in
    <:html<$st$ >>
  ) |> List.map ~f:Cow.Html.to_string |> List.map ~f:print_endline
  
