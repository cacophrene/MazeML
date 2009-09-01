(* 
 * dialog.ml
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

open Printf

module Filter =
  struct
    let text = GFile.filter
      ~name:"Texte"
      ~patterns:["*.txt"; "*.maze"] ()

    let pictures = GFile.filter
      ~name:"Images"
      ~patterns:["*.png"; "*.jpeg"; "*.bmp"] ()
  end

let toggle_solution () = Drawing.cells ~show:UI.toggle_solution#active ()

let display () =
  let t0 = Unix.gettimeofday () in
  let t = Maze.make
    ~rows:UI.rows#value_as_int
    ~cols:UI.cols#value_as_int in
  let t1 = Unix.gettimeofday () in
  Drawing.init t;
  Drawing.walls ();
  if UI.toggle_solution#active then toggle_solution ();
  let t2 = Unix.gettimeofday () in
  UI.print "Un labyrinthe de taille %d x %d (%d cases) a été créé par \
    exploration exhaustive (calcul : %.3f s, dessin : %.3f s)" 
    t.Maze.rows t.Maze.cols (t.Maze.last + 1) (t1 -. t0) (t2 -. t1)

(* Affiche un labyrinthe préalablement chargé depuis un fichier. Il n'est alors
 * plus possible de réaliser la construction progressive du labyrinthe car les
 * données de backtracking ont été effacées. *)
let display_loaded t =
  UI.rows#set_value (float t.Maze.rows);
  UI.cols#set_value (float t.Maze.cols);
  Drawing.init t;
  Drawing.walls ();
  if UI.toggle_solution#active then toggle_solution ()

(* Construction progressive du labyrinthe. La fonction utilisée renvoie la 
 * structure de type Maze.t (comme le fait Maze.make), mais elle y ajoute une
 * liste d'actions à effectuer pour construire progressivement le labyrinthe. *)
let display_interactive () =
  let t, l = Maze.make_interactive 
    ~rows:UI.rows#value_as_int 
    ~cols:UI.cols#value_as_int in
  Drawing.init t;
  Drawing.grid ();
  UI.toggle_solution#set_active false;
  Drawing.move l

let get_default_name ~typ = 
  let t = Drawing.current_maze () in
  sprintf "Maze-%dx%d.%s" t.Maze.rows t.Maze.cols typ

let show_save () = 
  let chooser = GWindow.file_chooser_dialog
    ~action:`SAVE 
    ~parent:UI.window
    ~destroy_with_parent:true
    ~title:"Enregistrer un labyrinthe"
    ~position:`CENTER_ON_PARENT () in
  chooser#add_button_stock `CANCEL `CANCEL;
  chooser#add_select_button_stock `SAVE `SAVE;
  chooser#add_filter Filter.text;
  chooser#set_current_name (get_default_name ~typ:"txt");
  if chooser#run () = `SAVE then begin
    match chooser#filename with
    | None -> ()
    | Some x -> UI.print "Enregistrement du fichier « %s »..." x;
      Maze.save (Drawing.current_maze ()) x
  end;
  chooser#destroy ()

let show_open () =
  let chooser = GWindow.file_chooser_dialog
    ~action:`OPEN 
    ~parent:UI.window
    ~destroy_with_parent:true
    ~title:"Ouvrir un labyrinthe"
    ~position:`CENTER_ON_PARENT () in
  chooser#add_button_stock `CANCEL `CANCEL;
  chooser#add_select_button_stock `OPEN `OPEN;
  chooser#add_filter Filter.text;
  if chooser#run () = `OPEN then begin
    match chooser#filename with
    | None -> ()
    | Some x ->
      match Maze.load x with
      | None -> UI.print "Fichier « %s » invalide !" x;
      | Some t -> UI.print "Chargement du fichier « %s »..." x;  
        display_loaded t
  end;
  chooser#destroy ()

let show_export () =
  let chooser = GWindow.file_chooser_dialog
    ~action:`SAVE 
    ~parent:UI.window
    ~destroy_with_parent:true
    ~title:"Exporter un labyrinthe"
    ~position:`CENTER_ON_PARENT () in
  chooser#add_button_stock `CANCEL `CANCEL;
  chooser#add_select_button_stock `SAVE `SAVE;
  chooser#add_filter Filter.pictures;
  chooser#set_current_name (get_default_name ~typ:"png");
  if chooser#run () = `SAVE then begin
    match chooser#filename with
    | None -> ()
    | Some x -> UI.print "Export du labyrinthe vers « %s »..." x;
      Drawing.export x
  end;
  chooser#destroy ()
