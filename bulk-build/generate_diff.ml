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
  String.Map.merge r2 r1
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

let proc res =
  let buf = Buffer.create 1024 in 
  List.map res ~f:(fun (pkg,data) ->
    let st =
      List.map data ~f:(function
      | New_and_works -> <:html<<span class="ok">&#9673;</span>&>>
      | New_and_fails -> <:html<<span class="err">&#9673;</span>&>>
      | Now_works -> <:html<<span class="ok2">&#9650;</span>&>>
      | Now_fails -> <:html<<span class="err2">&#9660;</span>&>>
      | Gone -> []) in
    <:html<$str:pkg$ $list:st$ &nbsp;>>
  ) |>
  List.iter ~f:(Cow.Html.output (`Buffer buf));
  print_endline (Buffer.contents buf)
 
let _ =
  let d1 = Sys.argv.(1) in
  let d2 = Sys.argv.(2) in
  let d1_os = Sys.readdir (sprintf "archive/%s/logs" d1) in
  let d2_os = Sys.readdir (sprintf "archive/%s/logs" d2) in
  let os = Array.filter d1_os ~f:(Array.mem d2_os) in
  let dir = sprintf "archive/%s/logs/%s" in
  let res = Array.map os ~f:(fun os -> diff (dir d1 os) (dir d2 os)) in
  Array.fold res ~init:String.Map.empty ~f:(fun acc b ->
   String.Map.fold b ~init:acc ~f:(fun ~key ~data -> String.Map.add_multi ~key ~data)
  ) |> String.Map.to_alist |> proc
