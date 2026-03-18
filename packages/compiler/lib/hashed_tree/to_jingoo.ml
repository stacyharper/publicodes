open Base
open Shared
open Jingoo
open Jg_types

let t_from_rule_name (rule_name : Rule_name.t) =
  Tstr (Rule_name.to_string rule_name)

let get_rule_str_unit (tree : Tree.t) (rule_name : Rule_name.t) : string option
    =
  let open Shared.Typ in
  let Tree.{typ; _} = Eval_tree.get_meta tree rule_name in
  match typ with
  | Some (Number (Some unit)) ->
      Some (Stdlib.Format.asprintf "%a" Shared.Units.pp unit)
  | _ ->
      None

let t_from_rule_type (tree : Tree.t) (rule_name : Rule_name.t) =
  let open Shared.Typ in
  let Tree.{typ; _} = Eval_tree.get_meta tree rule_name in
  match typ with
  | Some (Number _) ->
      Tstr "number"
  | Some (Literal String) ->
      Tstr "text"
  | Some (Literal Bool) ->
      Tstr "boolean"
  | Some (Literal Date) ->
      Tstr "date"
  | Some (Literal Name) ->
      Tstr "name"
  | None ->
      Tstr "unknown"

let t_from_date = function
  | Eval_tree.Date (Day {day; month; year}) ->
      Tobj [("year", Tint year); ("month", Tint month); ("day", Tint day)]
  | Date (Month {month; year}) ->
      Tobj [("year", Tint year); ("month", Tint month)]
  | _ ->
      failwith "Unsupported date format"

let t_from_op : Shared.Shared_ast.binary_op -> tvalue = function
  | Shared.Shared_ast.Add ->
      Tstr "add"
  | Sub ->
      Tstr "sub"
  | Mul ->
      Tstr "mul"
  | Div ->
      Tstr "div"
  | Pow ->
      Tstr "pow"
  | Eq ->
      Tstr "eq"
  | NotEq ->
      Tstr "neq"
  | Lt ->
      Tstr "lt"
  | Gt ->
      Tstr "gt"
  | GtEq ->
      Tstr "gte"
  | LtEq ->
      Tstr "lte"
  | And ->
      Tstr "and"
  | Or ->
      Tstr "or"
  | Min ->
      Tstr "min"
  | Max ->
      Tstr "max"

let is_lazy : Shared_ast.binary_op -> bool = function
  | And | Or | Lt | Gt | GtEq | LtEq | Pow | Div | Mul ->
      true
  | Add | Sub | Eq | NotEq | Min | Max ->
      false

let t_type_value typ value = Tobj [("type", Tstr typ); ("value", value)]

let find_title (meta : Shared_ast.rule_meta list) : string option =
  List.find_map meta ~f:(fun m ->
      match m with Shared_ast.Title t -> Some t | _ -> None )

let find_description (meta : Shared_ast.rule_meta list) : string option =
  List.find_map meta ~f:(fun m ->
      match m with Shared_ast.Description d -> Some d | _ -> None )

let t_from_meta (meta : Shared_ast.rule_meta list) =
  Tlist
    (List.filter_map meta ~f:(fun meta ->
         match meta with
         | Title title ->
             Some (t_type_value "title" @@ Tstr title)
         | Description desc ->
             Some (t_type_value "description" @@ Tstr desc)
         | Note note ->
             Some (t_type_value "note" @@ Tstr note)
         | Custom_meta meta ->
             Some (t_type_value "custom" @@ Tstr (Yojson.Safe.to_string meta))
         | Public ->
             None ) )

let rec t_from_rule_data ({value; _} : Tree.value) =
  match value with
  | Eval_tree.Const (Eval_tree.Number (n, units)) ->
      let unit =
        match units with
        | Some u ->
            Tstr (Stdlib.Format.asprintf "%a" Units.pp u)
        | None ->
            Tnull
      in
      t_type_value "number" @@ Tobj [("number", Tfloat n); ("unit", unit)]
  | Const (String s) ->
      t_type_value "text" @@ Tstr s
  | Const (Name (add, s)) ->
      t_type_value "string" @@ Tobj [("add", Tbool add); ("name", Tstr s)]
  | Const (Bool b) ->
      t_type_value "bool" @@ Tbool b
  | Const (Date d) ->
      t_type_value "date" @@ t_from_date (Date d)
  | Const Null ->
      t_type_value "null" Tnull
  | Const Undefined ->
      t_type_value "undefined" Tnull
  | Round (mode, precision, value) ->
      let rounding_mode =
        match mode with
        | Nearest ->
            Tstr "nearest"
        | Up ->
            Tstr "up"
        | Down ->
            Tstr "down"
      in
      t_type_value "round"
      @@ Tobj
           [ ("mode", rounding_mode)
           ; ("number", t_from_rule_data value)
           ; ("precision", t_from_rule_data precision) ]
  | Condition (cond, then_comp, else_comp) ->
      t_type_value "condition"
      @@ Tobj
           [ ("cond", t_from_rule_data cond)
           ; ("then", t_from_rule_data then_comp)
           ; ("_else", t_from_rule_data else_comp) ]
  | Binary_op ((op, _), left, right) ->
      t_type_value "binary_op"
      @@ Tobj
           [ ("op", t_from_op op)
           ; ("lazy", Tbool (is_lazy op))
           ; ("left", t_from_rule_data left)
           ; ("right", t_from_rule_data right) ]
  | Unary_op ((Neg, _), comp) ->
      t_type_value "unary_op"
      @@ Tobj [("op", Tstr "neg_op"); ("arg", t_from_rule_data comp)]
  | Unary_op ((Is_undef, _), comp) ->
      t_type_value "unary_op"
      @@ Tobj [("op", Tstr "is_undef"); ("arg", t_from_rule_data comp)]
  | Ref rule_name ->
      t_type_value "ref" @@ Tstr (Rule_name.to_string rule_name)
  | Get_context rule_name ->
      t_type_value "get_ctx" @@ Tstr (Rule_name.to_string rule_name)
  | Set_context {context; value} ->
      let context_items =
        List.map context ~f:(fun ((rule_name, _), value) ->
            Tobj
              [ ("name", Tstr (Rule_name.to_string rule_name))
              ; ("value", t_from_rule_data value) ] )
      in
      t_type_value "set_ctx"
      @@ Tobj [("expr", t_from_rule_data value); ("items", Tlist context_items)]

let t_from_rules hashed_tree =
  let rules =
    Base.Hashtbl.fold hashed_tree ~init:[] ~f:(fun ~key:rule ~data acc ->
        let rule_type = t_from_rule_type hashed_tree rule in
        let rule_name = t_from_rule_name rule in
        let rule_data = t_from_rule_data data in
        (rule_type, rule_name, rule_data) :: acc )
    |> List.sort ~compare:(fun (_, name1, _) (_, name2, _) ->
        String.compare (unbox_string name1) (unbox_string name2) )
  in
  Tlist
    (List.map rules ~f:(fun (rule_type, rule_name, rule_data) ->
         Tobj
           [ ("rule_type", rule_type)
           ; ("rule_name", rule_name)
           ; ("rule_data", rule_data) ] ) )

let t_from_output hashed_tree Model_outputs.{rule_name; parameters; meta; _} =
  let rule_type = t_from_rule_type hashed_tree rule_name in
  let title =
    find_title meta |> function None -> Tnull | Some str -> Tstr str
  in
  let description =
    find_description meta |> function None -> Tnull | Some str -> Tstr str
  in
  let return_type = t_from_rule_type hashed_tree rule_name in
  let metas = t_from_meta meta in
  let params =
    Tlist
      (List.map parameters ~f:(fun p ->
           Tobj
             [ ("type", t_from_rule_type hashed_tree p)
             ; ("value", Tstr (Rule_name.to_string p)) ] ) )
  in
  let unit =
    get_rule_str_unit hashed_tree rule_name
    |> function None -> Tnull | Some str -> Tstr str
  in
  Tobj
    [ ("rule_type", rule_type)
    ; ("rule_name", Tstr (Rule_name.to_string rule_name))
    ; ("title", title)
    ; ("description", description)
    ; ("return_type", return_type)
    ; ("metas", metas)
    ; ("unit", unit)
    ; ("params", params) ]

let t_from_outputs hashed_tree outputs =
  Tlist (List.map outputs ~f:(t_from_output hashed_tree))

let to_models tree outputs =
  [("rules", t_from_rules tree); ("outputs", t_from_outputs tree outputs)]
