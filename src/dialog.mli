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

(** Le module [Dialog] assure le dialogue avec l'utilisateur. Il fait le lien 
  * entre les éléments de l'interface définis dans le module [Components] et les
  * modules spécialisés [Maze] et [Drawing]. *)


(** {2 Affichage} *)

val display : unit -> unit
  (** [display ()] affiche un nouveau labyrinthe dont les caractéristiques
    * ont été choisies par l'utilisateur. *)

val display_interactive : unit -> unit
  (** Même chose que précédemment, mais les étapes de création du labyrinthe 
    * sont affichés à l'écran. *)

val toggle_solution : unit -> unit
  (** [toggle_solution ()] affiche ou masque le chemin qui relie la case de 
    * départ à la case d'arrivée (c.-à-d. la solution du labyrinthe). *)


(** {2 Sauvegarde, ouverture et export} *)

val show_save : unit -> unit
  (** [show_save ()] affiche une boîte de dialogue qui permet à l'utilisateur
    * de choisir le nom et l'emplacement du fichier dans lequel sera stocké le
    * labyrinthe. *)

val show_open : unit -> unit
  (** [show_open ()] affiche une boîte de dialogue qui permet à l'utilisateur
    * de choisir un fichier contenant les données d'un labyrinthe précédemment
    * enregistré. *)

val show_export : unit -> unit
  (** [show_export ()] affiche une boîte de dialogue qui permet à l'utilisateur
    * de choisir le nom du fichier (de type JPEG ou PNG) dans lequel le 
    * labyrinthe sera exporté. *)
