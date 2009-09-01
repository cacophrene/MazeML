(* 
 * mazeML.ml
 * This file is part of MazeML
 *
 * Copyright © 2008-2009 Cacophrene (cacophrene@gmail.com)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

open UI

let has_gui = ref true
let interactive = ref false

let set_value obj x = obj#set_value x
let set_color obj x = obj#set_color (GDraw.color (`NAME x))

let export_only str =
  try 
    Scanf.sscanf str "%d@,%d@,%s" (fun rows cols file ->
      Drawing.without_gui ~rows ~cols ~file);
    has_gui := false
  with exn -> prerr_endline (Printexc.to_string exn);
    exit 2

let spec = Arg.align [
  ("-rows", Arg.Float (set_value rows),
    "n Set rows number to n (default : 120)");
  ("-cols", Arg.Float (set_value cols),
    "n Set cols number to n (default : 190)");
  ("-wall", Arg.String (set_color wall_color), 
    "#RRGGBB Set wall color (default: #848484)");
  ("-cell", Arg.String (set_color cell_color), 
    "#RRGGBB Set cell color (default: #eac81c)");
  ("-back", Arg.Set_string Drawing.backcolor, 
    "#RRGGBB Set background color (default: white)");
  ("-alpha", Arg.Set_string Drawing.alpha,
    "#RRGGBB Set transparent color for PNG pictures (default: white)");
  ("--jpeg-quality", Arg.Set_int Drawing.jpeg_quality,
    "[0-100] Set the JPEG quality (default: 80)");
  ("--png-compression", Arg.Set_int Drawing.png_compression,
    "[0-9] Set the PNG compression level (default: 2)");
  ("-interactive", Arg.Set interactive,
    " Step-by-step drawing of newly generated mazes (default: disabled)");
  ("-rate", Arg.Set_int Drawing.speed,
    "n Set drawing rate to n milliseconds (default: 100 ms)");
  ("--without-gui", Arg.String export_only, 
    "r,c,file Build a new <r>x<c> maze, export it to <file> and exit");
]

let main () =
  (* Fenêtre principale. *)
  window#connect#destroy GMain.quit;

  (* Zone de dessin. *)
  drawing_area#event#add [`EXPOSURE];
  drawing_area#event#connect#expose Drawing.expose;

  let display = if !interactive then Dialog.display_interactive 
    else Dialog.display in

  (* Boutons. *)
  display_maze#connect#clicked display;
  toggle_solution#connect#toggled (fun () ->
    toggle_solution#set_label (
      match toggle_solution#active with
      | true  -> "Masquer la solution"
      | false -> "Afficher la solution"));
  toggle_solution#connect#toggled Dialog.toggle_solution;
  save#connect#clicked Dialog.show_save;
  load#connect#clicked Dialog.show_open;
  export#connect#clicked Dialog.show_export;

  (* Affichage et lancement. *)
  display ();
  window#show ();
  GMain.main ()

let _ = 
  Arg.parse spec (fun _ -> ()) "Usage: MazeML [OPTIONS] with";
  if !has_gui then main ()
