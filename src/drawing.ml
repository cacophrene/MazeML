(* 
 * drawing.ml
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

type maze_infos = {
  mutable maze : Maze.t;
  mutable or_x : int;
  mutable or_y : int;
  mutable size : int;
  mutable path : (int * int * int * int) list;
}

let this = { maze = Maze.empty; or_x = 0; or_y = 0; size = 0; path = [] }

let speed = ref 100

let alpha = ref "#ffffff"
let backcolor = ref "#ffffff"

let jpeg_quality = ref 80
let png_compression = ref 2

(* Couleurs prédéfinies utilisées par défaut. *)
module Color =
  struct
    let cell = `NAME "#719c00"    (* Un ton vert. *)
    let back = `NAME "#31689b"    (* Un ton bleu. *)
    let init = `NAME "#e2e2e2"
  end

module Coord =
  struct
    let getX col = this.or_x + this.size * col
    let getY row = this.or_y + this.size * row
  end

(* Met à jour la zone de dessin [UI.drawing_area] à partir des dessins 
 * effectuées dans la zone de dessin d'arrière-plan [UI.backing]. *)
let synchronize =
  let rect = Some (
    Gdk.Rectangle.create
      ~x:0
      ~y:0
      ~width:UI.width
      ~height:UI.height
  ) in fun () -> UI.drawing_area#misc#draw rect

let draw_filled_rect ?(backing = UI.backing) x y width height =
  backing#rectangle ~x ~y ~width ~height ~filled:true ()

(* Efface tous les tracés effectués dans la zone de dessin d'arrière-plan
 * [UI.backing]. *)
let flush ?(backing = UI.backing) () =
  let width, height = backing#size in
  backing#set_foreground (`NAME !backcolor);
  draw_filled_rect ~backing 0 0 width height;
  synchronize ()

let expose event =
  let area = GdkEvent.Expose.area event in
  let x = Gdk.Rectangle.x area
  and y = Gdk.Rectangle.y area
  and width = Gdk.Rectangle.width area
  and height = Gdk.Rectangle.height area in
  UI.drawing_area#misc#realize (); 
  let drawing = new GDraw.drawable UI.drawing_area#misc#window in
  drawing#put_pixmap ~x ~y ~xsrc:x ~ysrc:y ~width ~height UI.backing#pixmap;
  false

let convert clr = `NAME (
  Printf.sprintf "#%02x%02x%02x" 
    (Gdk.Color.red clr   lsr 8) 
    (Gdk.Color.green clr lsr 8) 
    (Gdk.Color.blue clr  lsr 8))

let init t =
  this.maze <- t;
  this.size <- min ((UI.width - 20) / t.Maze.cols) ((UI.height - 20) / t.Maze.rows);
  this.or_x <- (UI.width - this.size * t.Maze.cols) lsr 1;
  this.or_y <- (UI.height - this.size * t.Maze.rows) lsr 1;
  this.path <- Maze.get_solution ~init_x:this.or_x ~init_y:this.or_y 
    this.size this.maze;
  flush ()

let current_maze () = this.maze

(* Définit la couleur de premier plan puis trace la liste de segments <l> reçue
 * en entrée. Ces segments représentent les murs du labyrinthe (avec ou sans
 * portes ouvertes, selon les données). *)
let draw_wall_list ?(update = true) ?(backing = UI.backing) l =
  backing#set_foreground (convert UI.wall_color#color);
  backing#segments l;
  if update then synchronize ()

let walls ?(backing = UI.backing) () =
  draw_wall_list ~backing (Maze.get_segments 
    ~init_x:this.or_x
    ~init_y:this.or_y this.size this.maze)

(* Définit la couleur de premier plan puis affiche ou masque les cases du chemin
 * solution (couloir qui relie la case de départ à la case d'arrivée). *)
let cells ?(update = true) ?(backing = UI.backing) ?(show = true) () =
  backing#set_foreground (
    if show then convert UI.cell_color#color
    else `NAME !backcolor);
  let rec loop = function
    | [] -> if update then synchronize ()
    | (x, y, h, w) :: tail -> draw_filled_rect ~backing x y h w;
      loop tail
  in loop this.path

(* Calcule les coordonnées des lignes à tracer pour représenter toutes les 
 * lignes d'un labyrinthe (en vue de sa création pas à pas). *)
let get_rows_lines init_l =
  let colX = Coord.getX this.maze.Maze.cols in
  let rec loop l i =
    if i <= this.maze.Maze.rows then (
      let y' = Coord.getY i in 
      loop (((this.or_x, y'), (colX, y')) :: l) (i + 1)
    ) else l
  in loop init_l 0

(* Calcule les coordonnées des lignes à tracer pour représenter toutes les 
 * colonnes d'un labyrinthe (en vue de sa création pas à pas). *)
let get_cols_lines init_l =
  let rowY = Coord.getY this.maze.Maze.rows in
  let rec loop l i =
    if i <= this.maze.Maze.cols then (
      let x' = Coord.getX i in
      loop (((x', this.or_y), (x', rowY)) :: l) (i + 1)
    ) else l
  in loop init_l 0

(* Trace la grille complète à partir de laquelle un labyrinthe sera dessiné par
 * ouverture de différentes portes. Les cases sont initialement grisées pour 
 * mettre en relief le parcours de création du labyrinthe. *)
let grid () =
  UI.backing#set_foreground Color.init;
  draw_filled_rect 
    this.or_x
    this.or_y
    (this.maze.Maze.cols * this.size)
    (this.maze.Maze.rows * this.size);
  draw_wall_list (get_cols_lines (get_rows_lines []))

let draw_cell ?(color = `NAME !backcolor) x y =
  let size = this.size - 1 in
  UI.backing#set_foreground color;
  UI.backing#rectangle ~x ~y ~height:size ~width:size ~filled:true ()

let hide_door =
  let draw_line = UI.backing#line in
  fun x y dir -> 
    let k = this.size in
    UI.backing#set_foreground (`NAME !backcolor);
    match dir with
    | `North -> draw_line ~x:(x + 1) ~y ~x:(x + k - 1) ~y
    | `South -> let y = y + k in draw_line ~x:(x + 1) ~y ~x:(x + k - 1) ~y
    | `East  -> draw_line ~x ~y:(y + 1) ~x ~y:(y + k - 1)
    | `West  -> let x = x + k in draw_line ~x ~y:(y + 1) ~x ~y:(y + k - 1)

(* Active ou désactive les boutons de l'interface lors de la création pas à pas
 * d'un labyrinthe. *)
let global_set_sensitive x =
  UI.toggle_solution#misc#set_sensitive x;
  UI.display_maze#misc#set_sensitive x;
  UI.save#misc#set_sensitive x;
  UI.load#misc#set_sensitive x;
  UI.export#misc#set_sensitive x  

let move t =
  global_set_sensitive false;
  let len = Array.length t in
  let rec callback =
    let i = ref 0 and last = ref (0, 1, 1) in
    fun () ->
      let prev, x, y = !last in
      draw_cell x y;
      let curr, row, col, back = t.(!i) in
      let x = Coord.getX col + 1 and y = Coord.getY row + 1 in
      (* Ouvre la porte qui permet de passer d'une case à l'autre. *)
      hide_door (x - 1) (y - 1) (Maze.get_door ~prev ~curr);
      draw_cell ~color:(if back then Color.back else Color.cell) x y;
      last := (curr, x, y);
      synchronize ();
      UI.print "%s vers la case (%d, %d)" 
        (if back then "Rebrousse chemin" else "Progresse") row col;
      incr i;
      let res = !i < len in
      if not res then global_set_sensitive true;
      res
  in ignore (Glib.Timeout.add ~ms:!speed ~callback)

let check_filename str =
  if Filename.check_suffix str "png" then ("png", str) else
  if Filename.check_suffix str "bmp" then ("bmp", str) else
  if Filename.check_suffix str "jpeg" then ("jpeg", str) else
  ("png", str ^ ".png")

(* TODO: Corriger le problème... erreur de segmentation ! *)
let get_options = function
  | "png"  -> [] (*["compression", string_of_int !png_compression]*)
  | "jpeg" -> [] (*["quality", string_of_int !jpeg_quality]*)
  | _      -> []

let add_alpha =
  let to_tuple r g b = (r, g, b) in
  fun pixbuf ->
    try
      let transparent = Scanf.sscanf !alpha "#%2x%2x%2x" to_tuple in
      GdkPixbuf.add_alpha ~transparent pixbuf
    with _ -> pixbuf

let export ?(backing = UI.backing) str =
  let width, height = backing#size in
  let dest = GdkPixbuf.create ~has_alpha:true ~width ~height () in
  GdkPixbuf.get_from_drawable dest backing#pixmap;
  let typ, filename = check_filename str in
  GdkPixbuf.save
    ~filename 
    ~typ 
    ~options:(get_options typ) (add_alpha dest)

let without_gui ~rows ~cols ~file =
  let t0 = Unix.gettimeofday () in
  let t = Maze.make ~rows ~cols in
  let t1 = Unix.gettimeofday () in
  Printf.printf "Labyrinthe %d x %d (%d cases) créé en %.3f s\n%!"
    rows cols (t.Maze.last + 1) (t1 -. t0);
  let width = cols * 10 + 20 and height = rows * 10 + 20 in
  let backing = GDraw.pixmap ~width ~height () in
  flush ~backing ();
  this.maze <- t;
  this.size <- min ((width - 20) / t.Maze.cols) ((height - 20) / t.Maze.rows);
  this.or_x <- (width - this.size * t.Maze.cols) lsr 1;
  this.or_y <- (height - this.size * t.Maze.rows) lsr 1;
  this.path <- Maze.get_solution ~init_x:this.or_x ~init_y:this.or_y 
    this.size this.maze;
  walls ~backing ();
  cells ~backing ();
  let t2 = Unix.gettimeofday () in
  Printf.printf "Tracé du labyrinthe effectué en %.3f s\n\
    Merci de patienter : l'export en PNG est long...\n%!" (t2 -. t1);
  export ~backing file
