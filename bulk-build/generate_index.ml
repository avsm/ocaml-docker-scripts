#!/usr/bin/env ocamlscript
Ocaml.packs := ["git.unix"; "cmdliner"; "cow"; "cow.syntax"]
--

open Lwt.Infix

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

let commit_date ~fs ~hash =
  Git_unix.FS.read fs hash
  >>= function
  | None -> raise (Failure "Commit hash not found")
  | Some c ->
     match c with
     | Git.Value.Commit c ->
        let x = c.Git.Commit.committer in
        let date,_ = x.Git.User.date in
        Lwt.return date
     | _ -> raise (Failure "Hash is not a commit")

let print_tm tm =
  let open Unix in
  Printf.sprintf "%02d/%02d/%04d %02d:%02d"
    tm.tm_mday (tm.tm_mon+1) (tm.tm_year+1900) tm.tm_hour tm.tm_min

let info =
  let root = Sys.argv.(1) in
  Lwt_main.run (
    Git_unix.FS.create ~root () >>= fun fs ->
    Lwt_io.(read_lines stdin)
    |> Lwt_stream.to_list
    >|= List.map Git.SHA.of_hex
    >>= Lwt_list.map_s (fun hash -> commit_date ~fs ~hash >|= fun date -> (hash, date))
    >|= List.sort (fun (_,a) (_,b) -> Int64.compare b a)
    >|= Array.of_list
    >|= fun a -> Array.mapi (fun num (hash, date) ->
      Unix.gmtime (Int64.to_float date) |> fun tm ->
      Git.SHA.to_hex hash |> fun hash ->
      let d =
        if num + 1 < Array.length a then
          Some (hash, (Git.SHA.to_hex (fst a.(num+1))))
        else None
      in
      hash, (print_tm tm), d
     ) a |> Array.to_list
  )

(** HTML output functions *)
let html ~title body =
  <:html<<html>
    <head>
     <meta charset="UTF-8" /><link rel="stylesheet" type="text/css" href="theme.css"/>
     <title>$str:title$</title></head>
     <body>$body$</body></html>&>>


let results =
  let entries =
    List.map (fun (hash, date, diff) ->
     let diff_html =
       match diff with
       | None -> <:html< none >>
       | Some (d1,d2) ->
           ignore(Sys.command (Printf.sprintf "/bin/sh -c \"./generate_diff.ml %s %s > archive/%s/diff.html\"" d1 d2 d1));
           Cow.Xml.of_string (read_file (Printf.sprintf "archive/%s/diff.html" d1)) 
     in 
     <:html<
      <tr>
       <td class="index">$str:date$</td>
       <td class="index"><a href=$str:hash$>&#128279; $str:hash$</a><br /><div class="summary">$diff_html$</div></td>
      </tr>
     >>
    ) info in
  <:html<
    <h1>OCaml and OPAM Bulk Build Directory</h1>
    <table class="index">
    $list:entries$
    </table>
  >>
  
let generate_index () =
  let b =
    html ~title:"OCaml and OPAM Bulk Build Directory" results
    |> Cow.Html.to_string in
  Printf.eprintf "Generating: index.html\n%!";
  let fout = open_out "index.html" in
  Printf.fprintf fout "%s" b;
  close_out fout

let _ = generate_index ()
