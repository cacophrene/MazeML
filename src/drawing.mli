(* 
 * drawing.mli
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

(** Le module [Drawing] prend en charge le tracé des labyrinthes et le 
  * rafraîchissement de la zone de dessin. Il utilise la technique du {i double
  * buffering} pour éviter les clignotements et améliorer l'efficacité du 
  * tracé. *)


(** {2 Paramètres du module} 
  *
  * Ces paramètres peuvent être modifiés en ligne de commande au lancement de
  * l'application. En revanche, ils ne sont pas accessibles depuis l'interface
  * du programme, qui se veut sobre. *)

val speed : int ref
  (** Vitesse (en millisecondes) de la création interactive de labyrinthes.
    * @default: 100 ms. *)

val alpha : string ref
  (** Couleur rendue transparente lors de l'export.
    * @default "#ffffff" (blanc). *)

val backcolor : string ref
  (** Couleur d'arrière-plan de la zone de dessin.
    * @default "#ffffff" (blanc). *)

val jpeg_quality : int ref
  (** Qualité des images JPEG produites.
    * @default: 80 (qualité maximale : 100). *)

val png_compression : int ref
  (** Taux de compression des images PNG.
    * @default: 2 (compression maximale : 9). *)


(** {2 Rafraîchissement} *)

val expose : GdkEvent.Expose.t -> bool
  (** [expose ev] redessine les portions de la zone de tracé qui ont été 
    * effacées par superposition d'une autre fenêtre. *)


(** {2 Tracé du labyrinthe} *)

val init : Maze.t -> unit
  (** [init t] initialise les fonctions de tracé pour le labyrinthe [t]. Cette
    * fonction doit être appelée avant tout autre fonction de tracé de ce 
    * module.  *)

val current_maze : unit -> Maze.t
  (** [current_maze ()] renvoie le labyrinthe en cours de tracé. *)

val walls : ?backing:GDraw.pixmap -> unit -> unit
  (** [walls ()] affiche les murs du labyrinthe préalablement défini par 
    * [init]. *)

val cells : ?update:bool -> ?backing:GDraw.pixmap -> ?show:bool -> unit -> unit
  (** [cells ?show ()] masque ou affiche (selon la valeur de [show]) le 
    * chemin qui relie la case de départ à la case d'arrivée en colorant les 
    * cellules qui en font partie. *)

val grid : unit -> unit
  (** [grid ()] affiche la grille complète avant l'ouverture des portes qui 
    * forme le labyrinthe. *)

val move : Maze.move array -> unit
  (** [move t] affiche un à un les déplacements nécessaires à la création d'un
    * labyrinthe. Ceux-ci sont stockés dans le tableau [t]. *)

val export : ?backing:GDraw.pixmap -> string -> unit
  (** [export file] exporte le labyrinthe actif dans le fichier [file], dont le
    * type (PNG ou JPEG) est déterminé à partir de l'extension. La couleur 
    * [!alpha] est rendue transparente.
    * @default: type "png" lorsque [file] n'a pas d'extension connue. *)


(** {2 Dessin et export sans interface graphique} *)

val without_gui : rows:int -> cols:int -> file:string -> unit
  (** [without_gui ~rows:r ~cols:c ~file:f] crée un labyrinthe à [r] lignes et 
    * [c] colonnes et l'exporte, avec sa solution, dans le fichier [f]. Lorsque
    * cette fonction est appelée, le programme termine sans afficher son 
    * interface graphique. *)
