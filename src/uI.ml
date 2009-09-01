(* 
 * uI.ml
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

GMain.init ()

let width = 800
let height = 510

let window = GWindow.window
  ~title:"MazeML 1.9"
  ~resizable:false
  ~position:`CENTER ()

let vbox = GPack.vbox ~packing:window#add ()

let hbox = GPack.hbox ~packing:vbox#add ()

(* Zone de dessin. *)
let drawing_area = GMisc.drawing_area ~width ~height ~packing:hbox#add ()

(* Zone de dessin en arrière-plan. *)
let backing = GDraw.pixmap ~width ~height ()

let _ = GMisc.separator `VERTICAL ~packing:hbox#add ()

(* Panneau latéral. *)
let table = GPack.table
  ~rows:13
  ~columns:3
  ~row_spacings:5
  ~col_spacings:5
  ~border_width:10
  ~homogeneous:true
  ~packing:(hbox#pack ~expand:false) ()

let full_row_packing = table#attach ~left:0 ~right:3

let new_adjustment value upper = 
  GData.adjustment ~value ~lower:4.0 ~upper ~page_size:0.0 ()

let _ = GMisc.label 
  ~markup:"<span weight='bold' size='xx-large'>MazeML</span>"
  ~packing:(table#attach ~left:0 ~right:3 ~top:0) ()

let _ = GMisc.label 
  ~markup:"<b>Lignes :</b>"
  ~xalign:0.0
  ~packing:(table#attach ~left:0 ~right:2 ~top:1) ()

let rows = GEdit.spin_button
  ~adjustment:(new_adjustment 20. 240.)
  ~numeric:true
  ~update_policy:`IF_VALID
  ~packing:(table#attach ~left:2 ~top:1) ()

let _ = GMisc.label 
  ~markup:"<b>Colonnes :</b>"
  ~xalign:0.0
  ~packing:(table#attach ~left:0 ~right:2 ~top:2) ()

let cols = GEdit.spin_button
  ~adjustment:(new_adjustment 35. 390.)
  ~numeric:true
  ~update_policy:`IF_VALID
  ~packing:(table#attach ~left:2 ~top:2) ()

let display_maze = GButton.button
  ~label:"Mettre à jour"
  ~packing:(full_row_packing ~top:3) ()

let _ = GMisc.separator `HORIZONTAL 
  ~packing:(full_row_packing ~top:4) ()

let toggle_solution = GButton.toggle_button
  ~label:"Afficher la solution"
  ~packing:(full_row_packing ~top:5) ()

let _ = GMisc.separator `HORIZONTAL 
  ~packing:(full_row_packing ~top:6) ()

let save = GButton.button
  ~label:"Sauvegarder..." 
  ~packing:(full_row_packing ~top:7) ()

let load = GButton.button
  ~label:"Ouvrir..."
  ~packing:(full_row_packing ~top:8) ()

let export = GButton.button
  ~label:"Exporter..."
  ~packing:(full_row_packing ~top:9) ()


let _ = GMisc.separator `HORIZONTAL ~packing:(full_row_packing ~top:10) ()

let wall_color = GButton.color_button
  ~color:(GDraw.color (`NAME "#848484"))
  ~packing:(full_row_packing ~top:11) ()

let cell_color = GButton.color_button
  ~color:(GDraw.color (`NAME "#eac81c"))
  ~packing:(full_row_packing ~top:12) ()

(* Barre d'état de l'application. *)
let status = GMisc.statusbar ~packing:(vbox#pack ~expand:false) ()
let context = status#new_context ~name:"main"
let print fmt = Printf.ksprintf (context#flash ~delay:3000) fmt
