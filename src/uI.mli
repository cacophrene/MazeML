(* 
 * uI.mli
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

(** Le module [UI] rassemble tous les éléments de l'interface graphique
  * sans leur associer aucune action. Il fait donc partie des premiers modules
  * compilés et peut être utilisé par tous les autres. Il permet également de 
  * séparer nettement la partie algorithmique de l'interface. *)

val window : GWindow.window
  (** Fenêtre principale de l'application. *)

val height : int
  (** Hauteur de la fenêtre, en pixels. *)

val width : int
  (** Largeur de la fenêtre, en pixels. *)

val drawing_area : GMisc.drawing_area
  (** Zone de tracé des labyrinthes. *)

val backing : GDraw.pixmap
  (** Zone de tracé en arrière-plan. *)

val rows : GEdit.spin_button
  (** Définit le nombre de lignes du labyrinthe. *)

val cols : GEdit.spin_button
  (** Définit le nombre de colonnes du labyrinthe. *)

val display_maze : GButton.button
  (** Affiche un nouveau labyrinthe. *)

val toggle_solution : GButton.toggle_button
  (** Affiche ou masque la solution du labyrinthe. *)

val save : GButton.button
  (** Sauvegarde le labyrinthe actif. *)

val load : GButton.button
  (** Charge un labyrinthe précédemment sauvegardé. *)

val export : GButton.button
  (** Exporte un labyrinthe au format PNG. *)

val wall_color : GButton.color_button
  (** Définit la couleur des murs du labyrinthes. *)

val cell_color : GButton.color_button
  (** Définit la couleur des cases de la solution. *)

val print : ('a, unit, string, unit) format4 -> 'a
  (** Affiche un message dans la barre d'état. *)
