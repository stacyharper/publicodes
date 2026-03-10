type t = Tree.t

val to_models :
  t -> Shared.Model_outputs.t -> (string * Jingoo.Jg_types.tvalue) list

val from_typed_tree : Typed_tree.t -> t
