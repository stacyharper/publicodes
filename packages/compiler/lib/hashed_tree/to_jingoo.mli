val to_models :
  Tree.t -> Shared.Model_outputs.t -> (string * Jingoo.Jg_types.tvalue) list
(** [to_jinja ~hased_tree ~outputs] converts a hashed typed tree to its
		corresponding set of Jingoo models. *)
