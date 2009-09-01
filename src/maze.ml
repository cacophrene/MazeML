(* 
 * maze.ml
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
open Bigarray

type move = int * int * int * bool
type door = [ `North | `South | `East | `West ]

type t = { 
  buff : (int, int8_unsigned_elt, c_layout) Array1.t;
  rows : int;
  cols : int;
  last : int;
}

type memo = { mutable flag : bool; mutable cell : int }

(* OCaml 3.10 : Enlever "unsafe_" dans les deux lignes ci-dessous pour pouvoir
 * compiler. Le code est alors légèrement moins efficace (une seconde de plus
 * pour r = c = 7000 sur mon PC portable Acer Aspire 2012). *)
let uget t n = Array1.unsafe_get t.buff n
let uset t n x = Array1.unsafe_set t.buff n x

let make = Array1.create int8_unsigned c_layout

let empty = { buff = make 0; rows = 0; cols = 0; last = 0 }

module Index =
  struct
    let get_row t n = n / t.cols
    let get_col t n = n mod t.cols

    let is_fst_row t n = n < t.cols
    let is_fst_col t n = get_col t n = 0
    let is_lst_row t n = t.rows - get_row t n = 1
    let is_lst_col t n = t.cols - get_col t n = 1

    let get_dir_N t n = if is_fst_row t n then -1 else n - t.cols
    let get_dir_W t n = if is_fst_col t n then -1 else n - 1
    let get_dir_S t n = if is_lst_row t n then -1 else n + t.cols
    let get_dir_E t n = if is_lst_col t n then -1 else n + 1
  end

module Bits =
  struct
    let get4A t n = uget t n lsr 4
    let get4B t n = uget t n land 15
    let del4A t n = uset t n (get4B t n)
  end

(* Initialise le générateur de nombres pseudo-aléatoires et crée un nouveau
 * labyrinthe dont toutes les portes sont initialement fermées. *)
let init r c =
  Random.self_init ();
  let rc = r * c in
  let bigarray = make rc in
  Array1.fill bigarray 0;
  { buff = bigarray; rows = r; cols = c; last = rc - 1 }

(* Le profilage avec gprof indique clairement que cette version est plus rapide
 * que celle, plus esthétique, à base de List.filter. Une amélioration nette des
 * performances est visible pour de gros labyrinthes (plus de 1000 x 1000). *)
let next_directions t n =
  let dN = Index.get_dir_N t n and dW = Index.get_dir_W t n
  and dE = Index.get_dir_E t n and dS = Index.get_dir_S t n in
  let l = if dN < 0 || uget t dN <> 0 then [ ] else [(8, 1, dN)]     in
  let l = if dW < 0 || uget t dW <> 0 then  l  else  (4, 2, dW) :: l in
  let l = if dE < 0 || uget t dE <> 0 then  l  else  (2, 4, dE) :: l in
  let l = if dS < 0 || uget t dS <> 0 then  l  else  (1, 8, dS) :: l in
  l

module GoTo =
  struct
    let prev t n =
      match Bits.get4A t n with
      | 1 -> Index.get_dir_S t n
      | 2 -> Index.get_dir_E t n
      | 4 -> Index.get_dir_W t n
      | 8 -> Index.get_dir_N t n
      | _ -> invalid_arg "Maze.GoTo.prev"

    let next t n (this_door, next_door, p) =
      uset t n (uget t n lor this_door);
      uset t p ((next_door lsl 4) lor next_door);
      p

    (* 11/01/09 : Nouvelle implémentation plus performante, qui ne convertit pas
     * la liste des directions en tableau. Gain ~ 4 secondes pour r = c = 7000
     * sur mon PC portable Acer Aspire 2012. *)
    let rand t n l = 
      next t n (
        match l with
        | [x; y] -> if Random.bool () then x else y
        | _      -> List.nth l (Random.int 3)
      )
  end
let update t memo n =
  let prev = GoTo.prev t n in
  begin match n = t.last with
    | true -> memo.flag <- true; memo.cell <- prev
    | _ when memo.flag && n = memo.cell -> memo.cell <- prev 
    | _ -> Bits.del4A t n
  end;
  prev

let make ~rows:r ~cols:c =
  if r < 0 || c < 0 then invalid_arg "Maze.make";
  let t = init r c in
  let rec loop memo back = function
    | 0 when back -> ()
    | n ->
      match next_directions t n with
      | [ ] -> loop memo true  (update t memo n)
      | [x] -> loop memo false (GoTo.next t n x)
      |  l  -> loop memo false (GoTo.rand t n l)
  in loop {flag = false; cell = 0} false 0;
  uset t 0 (uget t 0 lor 8);
  uset t t.last (uget t t.last lor 1);
  t

let make_interactive ~rows:r ~cols:c =
  if r < 0 || c < 0 then invalid_arg "Maze.make_interactive";
  let t = init r c in
  let rec loop l memo back = function
    | 0 when back -> l
    | n ->
      let p, b = match next_directions t n with
        | [ ] -> (update t memo n, true)
        | [x] -> (GoTo.next t n x, false)
        |  k  -> (GoTo.rand t n k, false) in
      let tuple = (p, Index.get_row t p, Index.get_col t p, b) in
      loop (tuple :: l) memo b p in
  let actions = loop [0, 0, 0, false] {flag = false; cell = 0} false 0 in
  uset t 0 (uget t 0 lor 8);
  uset t t.last (uget t t.last lor 1);
  (t, Array.of_list (List.rev actions))

let get_rows t = t.rows
let get_cols t = t.cols

let get_door ~prev:p ~curr:n =
  match n - p with
  |  1 -> `East
  | -1 -> `West
  | n when n < 0 -> `South
  | _ -> `North

let save t file =
  let oc = open_out file in
    fprintf oc "ROWS %04d COLS %04d\n" t.rows t.cols;
    for i = 0 to t.last do
      output_char oc (char_of_int (uget t i))
    done;
  close_out oc

let new_buffer ic =
  let buff = Array1.map_file 
    (Unix.descr_of_in_channel ic) 
    ~pos:20L int8_unsigned c_layout false (-1) in
  close_in ic;
  buff

let load file =
  try
    let ic = open_in file in
    let r, c = Scanf.fscanf ic "ROWS %d COLS %d\n" (fun x y -> x, y) in
    Some { buff = new_buffer ic; rows = r; cols = c; last = r * c - 1 }
  with _ -> None

module Segm =
  struct
    let dS ix iy n t i = 
      let x = ix + (Index.get_col t i) * n in
      let y = iy + (Index.get_row t i + 1) * n in
      (x, y), (x + n, y)
    let dE ix iy n t i =
      let x = ix + (Index.get_col t i + 1) * n in
      let y = iy + (Index.get_row t i) * n in
      (x, y), (x, y + n)
    let dW ix iy n t i =
      let x = ix + (Index.get_col t i) * n in 
      let y = iy + (Index.get_row t i) * n in
      (x, y), (x, y + n)
    let dN ix iy n t i =
      let x = ix + (Index.get_col t i) * n in 
      let y = iy + (Index.get_row t i) * n in
      (x, y), (x + n, y)
  end

let get_segments ?(init_x = 40) ?(init_y = 40) n t =
  let rec loop l = function
    | 0 -> l
    | i -> let j = i - 1 in
      let door = Bits.get4B t j in
      let l = if door land 1 = 0 then Segm.dS init_x init_y n t j :: l else l in
      let l = if door land 2 = 0 then Segm.dE init_x init_y n t j :: l else l in
      let l = if door land 4 = 0 then Segm.dW init_x init_y n t j :: l else l in
      let l = if door land 8 = 0 then Segm.dN init_x init_y n t j :: l else l in
      loop l j
  in loop [] (t.last + 1)

(* On souhaite obtenir un tracé continu du chemin solution. Or les portes 
 * ouvertes créent des lignes non colorées qui rendent le tracé discontinu. On
 * corrige ce problème en modifiant la taille des rectangles dessinés en 
 * fonction des portes ouvertes :
 *   - en modifiant les coordonnées x et y;
 *   - en modifiant la largeur et la hauteur;
 *   - en traçant plusieurs rectangles. *)
let door = [1; 2; 8; 9; 6; 4]
let func = [
  (fun x y k -> x + 1, y + 1, k - 1, k    );
  (fun x y k -> x + 1, y + 1, k    , k - 1);
  (fun x y k -> x + 1, y    , k - 1, k    );
  (fun x y k -> x + 1, y    , k - 1, k + 1);
  (fun x y k -> x    , y + 1, k + 1, k - 1);
  (fun x y k -> x    , y + 1, k    , k - 1)]

let find = 
  let htbl = Hashtbl.create 7 in
  List.iter2 (Hashtbl.add htbl) door func;
  Hashtbl.find htbl

let get_cell init_x init_y k t n l =
  let x = init_x + (Index.get_col t n) * k 
  and y = init_y + (Index.get_row t n) * k in
  let d = Bits.get4B t n land (lnot (Bits.get4A t n)) in
  try find d x y k :: l with Not_found ->
    let small = 
      if d <  8 then 1 else 
      if d < 12 then 2 else 
      if d < 14 then 4 else 6
    in find (d - small) x y k :: find small x y k :: l

let get_solution ?(init_x = 40) ?(init_y = 40) size t =
  let rec loop l n =
    let l' = get_cell init_x init_y size t n l in
    match Bits.get4A t n with
    | 0 -> l'
    | 1 -> loop l' (Index.get_dir_S t n)
    | 2 -> loop l' (Index.get_dir_E t n)
    | 4 -> loop l' (Index.get_dir_W t n)
    | _ -> loop l' (Index.get_dir_N t n)
  in loop [] t.last
