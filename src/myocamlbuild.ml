(* Script de compilation ocamlbuild. *)

open Ocamlbuild_pack
open Ocamlbuild_plugin

(* External libraries. *)
let dirs = ["-I"; "+lablgtk2"]
let libs = ["lablgtk"; "unix"; "str"; "bigarray"]
let optf = ["-inline"; "1000000"; "-unsafe"; "-nodynlink"; "-ffast-math"]

let _ =
  dispatch begin function 
    | After_options ->
      Log.level := 0;
      Options.ocaml_libs := libs;
      Options.ocaml_cflags := dirs @ ["-g"; "-w"; "s"];
      Options.ocaml_lflags := dirs @ optf
    | _ -> ()
  end
