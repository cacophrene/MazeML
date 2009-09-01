(* 
 * maze.mli
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

(** Le module [Maze] crée des {i labyrinthes parfaits}, c'est-à-dire conçus de
  * telle façon qu'il n'existe qu'un seul chemin reliant deux cases données. Il
  * permet également de déterminer les actions à effectuer pour construire un
  * labyrinthe de façon interactive. 
  *
  * {2 Principe de l'algorithme}
  *
  * Un labyrinthe de [r] lignes et [c] colonnes est représenté à l'aide d'un 
  * tableau d'entiers 8 bits non signés de longueur [rc]. Les 4 bits de poids 
  * fort d'un entier codent les informations de backtracking, tandis que les 4
  * bits de poids faible codent les portes ouvertes.
  *
  * L'ouverture d'un couloir se poursuit jusqu'à ce qu'une impasse soit 
  * rencontrée (toutes les cases voisines ont déjà été visitées). L'algorithme
  * utilise alors les données de backtracking pour rebrousser chemin. Ces 
  * données sont d'ailleurs effacées lors du rebroussement, à l'exception 
  * notable du chemin qui relie la première à la dernière case. Il s'agit en 
  * effet du chemin solution, qui est donc établi lors de la construction du
  * labyrinthe.
  *)

open Bigarray

type move = int * int * int * bool
type door = [ `North | `South | `East | `West ]
  (** Directions. Ce type est utilisé par la fonction [get_direction] pour 
    * indiquer quelle porte doit être ouverte pour passer d'une case à une 
    * autre. *)

type t = private { 
  buff : (int, int8_unsigned_elt, c_layout) Array1.t;
  rows : int;                   (** Nombre de lignes du labyrinthe.           *)
  cols : int;                   (** Nombre de colonnes du labyrinthe.         *)
  last : int;                   (** Indice de la dernière case du labyrinthe. *)
}
  (** Le type des labyrinthes construits par le module [Maze]. *)


(** {2 Création et paramètres} *)

val empty : t
  (** Labyrinthe vide. Cette variable sans grand intérêt peut être utilisée pour
    * initialiser une référence qui stocke un labyrinthe. *)

val make : rows:int -> cols:int -> t
  (** [make ~rows:r ~cols:c] construit un labyrinthe parfait à [r] lignes et [c] 
    * colonnes. Cette fonction est récursive terminale.
    * @raise Invalid_argument si [r < 0] ou [c < 0]. *)

val make_interactive : rows:int -> cols:int -> t * move array
  (** Même chose que [make] ci-dessus, mais la fonction renvoie les données qui
    * permettent de construire le labyrinthe pas à pas. Ces données consistent
    * en un triplet [(n, r, c, b)] où [n] désigne l'indice de la case à 
    * atteindre, [r] et [c] ses coordonnées (ligne et colonne), et [b] si l'on
    * est en mode {i backtracking}. *)

val get_rows : t -> int
  (** [get_rows t] renvoie le nombre de lignes du labyrinthe [t]. Opération en
    * temps constant (le labyrinthe stocke sa taille). Il est également possible
    * d'utiliser [t.Maze.rows]. *)

val get_cols : t -> int
  (** [get_cols t] renvoie le nombre de colonnes du labyrinthe [t]. Opération en
    * temps constant (le labyrinthe stocke sa taille). Il est également possible
    * d'utiliser [t.Maze.cols]. *)

val get_door : prev:int -> curr:int -> door
  (** [get_direction ~prev:p ~curr:c] renvoie une valeur qui indique quelle 
    * porte doit être ouverte pour passer de la case d'indice [p] à la case
    * d'indice [c]. *)


(** {2 Ouverture et enregistrement} *)

val save : t -> string -> unit
  (** [save t file] enregistre le labyrinthe [t] dans le fichier [file]. Le 
    * fichier créé est un fichier texte de [get_rows t * get_cols t + 20] 
    * octets. *)

val load : string -> t option
  (** [load file] charge un labyrinthe précédemment sauvegardé dans le fichier
    * [file]. La fonction renvoie [None] en cas d'erreur (notamment lorsque le
    * fichier est invalide). *)


(** {2 Affichage et résolution} *)

val get_segments :
  ?init_x:int -> 
  ?init_y:int -> int -> t -> ((int * int) * (int * int)) list
  (** [get_segments n l] renvoie la liste des segments à dessiner pour 
    * représenter le labyrinthe [l] avec des cellules de côté [n]. Les arguments
    * optionnels [init_x] et [init_y] permettent de définir l'origine. *)

val get_solution :
  ?init_x:int -> 
  ?init_y:int -> int -> t -> (int * int * int * int) list
  (** [get_solution l] renvoie la liste des cases à parcourir pour rejoindre
    * la case d'arrivée (en bas à droite) du labyrinthe [l] à partir de la case
    * de départ (en haut à gauche). {b Remarque :} Les cases sont renvoyées sous
    * forme de 4-uplets de la forme [(x, y, width, height)]. *)
