(*do this twice; once with objects/classes and once with modules
  --m1 and m2 are empty maps that need to be provided by client code-- *)
(*March 2019 -- very dumb mistake in prior commits...not a true bimap.
  Use a functor so we have access to something satisfying Comparable.S 
  and force type of map to use 'a list and 'b list. And fix the functions
  for adding values, changing values, etc.
*)
module Bimap_multi (ModuleA : Core.Comparable.S)(ModuleB : Core.Comparable.S) = struct
  class ['a, 'b] bimap_multi_class (m1 : 'b list ModuleA.Map.t) (m2 : 'a list ModuleB.Map.t) = object(self)
    val mutable forward_map : ('b list ModuleA.Map.t ref) = ref (m1 : 'b list ModuleA.Map.t)
    val mutable reverse_map : ('a list ModuleB.Map.t ref) = ref (m2 : 'a list ModuleB.Map.t)

    method private empty_forward_map () =
      forward_map := ModuleA.Map.empty
    method private empty_reverse_map () =
      reverse_map := ModuleB.Map.empty

    method add_multi ~key ~data =
      let update_maps () =
        let () = forward_map :=
                   (ModuleA.Map.add_multi !forward_map ~key ~data) in
        self#add_multi_inverse ~key:data ~data:key in
      if ModuleA.Map.mem !forward_map key then
        if Core.List.mem
             (ModuleA.Map.find_exn !forward_map key) data
             ~equal:(ModuleB.equal) then ()
        else 
          update_maps ()
      else
        update_maps ()

    method add_multi_inverse ~key ~data =
      let update_maps () =
        let () = reverse_map := (ModuleB.Map.add_multi !reverse_map ~key ~data) in
        self#add_multi ~key:data ~data:key in
      if ModuleB.Map.mem !reverse_map key then
        if Core.List.mem
             (ModuleB.Map.find_exn !reverse_map key) data
             ~equal:(ModuleA.equal) then ()
        else 
          update_maps ()
      else
        update_maps ()

    method change ~key ~f =
      (* A -> 1,2,3 | B-> 4,5,6 | C -> 7,8,9 
         1->A|2->A|3->A|4->B|5->B|6->B ... etc
         but after some change could end up with
         A -> 2,4,6 | B-> 4,5,6 | C -> 7,8,9
         2->A|4->A,B|5->B|6->A,B| ... etc
      *)
      let old_value_list = ModuleA.Map.find_exn !forward_map key in 
      let () = forward_map := (ModuleA.Map.change !forward_map key ~f) in
      let new_values = ModuleA.Map.find_exn !forward_map key in
    (*--- now only need to fixup the reverse mapping ---
       For each old value (key in reverse mapping):
         a) if the only binding is to ~key provided to this function then remove the old value (key in reverse mapping)
         b) else filter the list of values to remove the ~key provided to this function
       And then for each new value, add them to reverse mapping  *)
      let () = Core.List.iter old_value_list
                 ~f:(fun k ->
                   let old_reverse_bindings = ModuleB.Map.find_exn !reverse_map k in
                   if (Core.List.count old_reverse_bindings ~f:(fun _v -> true)) > 1 then
                     let new_reverse_bindings = Core.List.filter old_reverse_bindings ~f:(fun v -> not (v = key)) in
                     let () = reverse_map := ModuleB.Map.remove !reverse_map k in
                     reverse_map :=
                       ModuleB.Map.add_exn !reverse_map ~key:k ~data:new_reverse_bindings
                   else
                     reverse_map := ModuleB.Map.remove !reverse_map k
                 ) in
      Core.List.iter new_values
        ~f:(fun k -> 
          reverse_map := ModuleB.Map.add_multi !reverse_map ~key:k ~data:key 
        )

    method change_inverse ~key ~f =
      let old_value_list = ModuleB.Map.find_exn !reverse_map key in 
      let () = reverse_map := (ModuleB.Map.change !reverse_map key ~f) in
      let new_values = ModuleB.Map.find_exn !reverse_map key in
      let () = Core.List.iter old_value_list
                 ~f:(fun k ->
                   let old_reverse_bindings = ModuleA.Map.find_exn !forward_map k in
                   if (Core.List.count old_reverse_bindings ~f:(fun _v -> true)) > 1 then
                     let new_reverse_bindings = Core.List.filter old_reverse_bindings ~f:(fun v -> not (v = key)) in
                     let () = forward_map := ModuleA.Map.remove !forward_map k in
                     forward_map :=
                       ModuleA.Map.add_exn !forward_map ~key:k ~data:new_reverse_bindings
                   else
                     forward_map := ModuleA.Map.remove !forward_map k
                 )  in
      Core.List.iter new_values
        ~f:(fun k -> 
          forward_map := ModuleA.Map.add_multi !forward_map ~key:k ~data:key 
        )

    method private create_inverse_map_from_forward_map () =
      let () = self#empty_reverse_map () in 
      ModuleA.Map.iter_keys !forward_map
	     ~f:(fun k ->
               let values = ModuleA.Map.find_exn !forward_map k in
		 let rec helper v2bkeys =
		   match v2bkeys with
		   | [] -> ()
		   | h::t ->
		      let () = reverse_map :=
                                 ModuleB.Map.add_multi !reverse_map ~key:h ~data:k in
		      helper t in
		 helper values)

    method private create_forward_map_from_reverse_map () =
      let () = self#empty_forward_map () in 
      ModuleB.Map.iter_keys !reverse_map
	     ~f:(fun k ->
		 let values = ModuleB.Map.find_exn !reverse_map k in
		 let rec helper v2bkeys =
		   match v2bkeys with
		   | [] -> ()
		   | h::t ->
		      let () = forward_map :=
				 ModuleA.Map.add_multi !forward_map ~key:h ~data:k in
		      helper t in
		 helper values)
    method count ~f =
      ModuleA.Map.count !forward_map ~f
    method count_inverse ~f =
      ModuleB.Map.count !reverse_map ~f
    method counti ~f =
      ModuleA.Map.counti !forward_map ~f
    method data =
      ModuleA.Map.data !forward_map
    method data_inverse =
      ModuleB.Map.data !reverse_map
    method empty () =
      (*let () = forward_map := (Core.Map.empty ~comparator:(Core.Map.comparator !forward_map)) in
      reverse_map := (Core.Map.empty ~comparator:(Core.Map.comparator !reverse_map))*)
      let () = self#empty_forward_map () in
      self#empty_reverse_map ()
    method exists ~f =
      ModuleA.Map.exists !forward_map ~f
    method exists_inverse ~f =
      ModuleB.Map.exists !reverse_map ~f
    method existsi ~f =
      ModuleA.Map.existsi !forward_map ~f
    method existsi_inverse ~f =
      ModuleB.Map.existsi !reverse_map ~f
    method find ~key =
      ModuleA.Map.find !forward_map key
    method find_inverse ~key =
      ModuleB.Map.find !reverse_map key 
    method find_exn ~(key:ModuleA.Map.Key.t) =
      ModuleA.Map.find_exn !forward_map key
    method find_exn_inverse ~key =
      Core.Map.find_exn !reverse_map key
    method filter ~f =
      let () = forward_map := (ModuleA.Map.filter !forward_map ~f) in
      (*in bimap_multi, unlike bimap, the filter function cannot 
        be applied to the inverse map through filter_keys function*)
      self#create_inverse_map_from_forward_map
    method filter_inverse ~f =
      let () = reverse_map := (ModuleB.Map.filter !reverse_map ~f) in
      self#create_forward_map_from_reverse_map
    method filter_keys ~f =
      let () = forward_map := (ModuleA.Map.filter_keys !forward_map ~f) in
      self#create_inverse_map_from_forward_map
    method filter_keys_inverse ~f =
      let () = reverse_map := (ModuleB.Map.filter_keys !reverse_map ~f) in
      self#create_forward_map_from_reverse_map
    method filteri ~f =
      let () = forward_map := (ModuleA.Map.filteri !forward_map ~f) in
      self#create_inverse_map_from_forward_map
    method filteri_inverse ~f =
      let () = reverse_map := (ModuleB.Map.filteri !reverse_map ~f) in
      self#create_forward_map_from_reverse_map
    method filter_map ~f =
      let () = forward_map := (ModuleA.Map.filter_map !forward_map ~f) in
      self#create_inverse_map_from_forward_map
    method filter_map_inverse ~f =
      let () = reverse_map := (ModuleB.Map.filter_map !reverse_map ~f) in
      self#create_forward_map_from_reverse_map
    method fold : 'e. init:'e -> f:(key:'a -> data:'b list -> 'e -> 'e) -> 'e = 
      (fun ~init ~f -> ModuleA.Map.fold !forward_map ~init ~f)
    method fold_inverse : 'e. init:'e -> f:(key:'b -> data:'a list -> 'e -> 'e) -> 'e =
      (fun ~init ~f -> ModuleB.Map.fold !reverse_map ~init ~f)
(*    method fold_range_inclusive ~min ~max ~init ~f =
      Core.Map.fold_range_inclusive !forward_map ~min ~max ~init ~f*)
    method fold_right : 'e. init:'e -> f:(key:'a -> data:'b list -> 'e -> 'e) -> 'e =
      (fun ~init ~f -> ModuleA.Map.fold_right !forward_map ~init ~f)
    method fold_right_inverse : 'e. init:'e -> f:(key:'b -> data:'a list -> 'e -> 'e) -> 'e =
      (fun ~init ~f -> ModuleB.Map.fold_right !reverse_map ~init ~f)
    method for_all ~f =
      ModuleA.Map.for_all !forward_map ~f
    method for_all_inverse ~f =
      ModuleB.Map.for_all !reverse_map ~f
    method is_empty =
      ModuleA.Map.is_empty !forward_map

    method iter_keys ~f =
      ModuleA.Map.iter_keys !forward_map ~f
    method iter_keys_inverse ~f =
      ModuleB.Map.iter_keys !reverse_map ~f

    method iter ~f =
      ModuleA.Map.iter !forward_map ~f
    method iter_inverse ~f =
      ModuleB.Map.iter !reverse_map ~f
    method iteri ~f =
      ModuleA.Map.iteri !forward_map ~f
    method iteri_inverse ~f =
      ModuleB.Map.iteri !reverse_map ~f
    method keys =
      ModuleA.Map.keys !forward_map
    method keys_inverse =
      ModuleB.Map.keys !reverse_map
    method length =
      ModuleA.Map.length !forward_map
    method map ~f =
      let () = forward_map := (ModuleA.Map.map !forward_map ~f) in
      (*let () = reverse_map := Core.Map.empty ~comparator:(Core.Map.comparator !reverse_map) in*)
      let () = self#empty_reverse_map () in 
      ModuleA.Map.iter_keys
	!forward_map
	~f:(fun k ->
	    self#add_inverse_values (ModuleA.Map.find_exn !forward_map k) k)
    method map_inverse ~f =
      let () = reverse_map := (ModuleB.Map.map !reverse_map ~f) in
      (*let () = forward_map := Core.Map.empty ~comparator:(Core.Map.comparator !forward_map) in*)
      let () = self#empty_forward_map () in 
      ModuleB.Map.iter_keys
	!reverse_map
	~f:(fun k -> forward_map :=
		       ModuleA.Map.add_multi !forward_map ~key:(ModuleB.Map.find_exn !reverse_map k) ~data:k)
    method mapi ~f =
      let () = forward_map := (Core.Map.mapi !forward_map ~f) in
      (*let () = reverse_map := Core.Map.empty ~comparator:(Core.Map.comparator !reverse_map) in*)
      let () = self#empty_reverse_map () in 
      Core.Map.iter_keys
	!forward_map
	~f:(fun k ->
	    self#add_inverse_values (Core.Map.find_exn !forward_map k) k)
    method mapi_inverse ~f =
      let () = reverse_map := (Core.Map.mapi !reverse_map ~f) in
      (*let () = forward_map := Core.Map.empty ~comparator:(Core.Map.comparator !forward_map) in*)
      let () = self#empty_forward_map () in 
      Core.Map.iter_keys
	!reverse_map
	~f:(fun k -> forward_map :=
		       Core.Map.add_multi !forward_map ~key:(Core.Map.find_exn !reverse_map k) ~data:k)
    method mem key =
      Core.Map.mem !forward_map key
    method mem_inverse key =
      Core.Map.mem !reverse_map key
    method min_elt =
      Core.Map.min_elt !forward_map
    method min_elt_exn =
      Core.Map.min_elt_exn !forward_map
    method min_elt_inverse =
      Core.Map.min_elt !reverse_map
    method min_elt_exn_inverse =
      Core.Map.min_elt_exn !reverse_map
    method max_elt =
      Core.Map.max_elt !forward_map
    method max_elt_exn =
      Core.Map.max_elt_exn !forward_map
    method max_elt_inverse =
      Core.Map.max_elt !reverse_map
    method max_elt_exn_inverse =
      Core.Map.max_elt_exn !reverse_map
    method nth int =
      Core.Map.nth !forward_map int
    method nth_inverse int =
      Core.Map.nth !reverse_map int
    method remove ~key =
      let reverse_keys = Core.Map.find_exn !forward_map key in 
      let () = forward_map := (Core.Map.remove !forward_map key) in
      self#remove_inverse_keys reverse_keys
    method private remove_inverse_keys klist = 
      let rec remove_keys k =
	match k with
	| h :: t ->
	   let () = reverse_map := (Core.Map.remove !reverse_map h) in
	   remove_keys t
	| [] -> () in
      remove_keys klist
    method remove_inverse ~key =
      let fwd_key = Core.Map.find_exn !reverse_map key in 
      let () = reverse_map := (Core.Map.remove !reverse_map key) in
      let fwd_values = self#find_exn ~key:fwd_key in
      let new_fwd_values = (Core.List.filter fwd_values ~f:(fun x -> not (x = key))) in 
      let () = forward_map := (Core.Map.remove !forward_map fwd_key) in
      forward_map := (Core.Map.set !forward_map  ~key:fwd_key ~data:new_fwd_values)
    method remove_multi ~key =
      try
	let values = Core.Map.find_exn !forward_map key in
	let head_element = Core.List.nth_exn values 0 in 
	let () = forward_map := (Core.Map.remove_multi !forward_map key) in
	reverse_map := (Core.Map.remove !reverse_map head_element)
      with e -> ()
    method to_alist ?key_order () =
      match Core.Option.is_some key_order with
      | false -> Core.Map.to_alist !forward_map
      | true -> Core.Map.to_alist ~key_order:(Core.Option.value_exn key_order) !forward_map
    method update key ~f =
      let oldvalues = Core.Map.find_exn !forward_map key in
      let () = forward_map := (Core.Map.update !forward_map key ~f) in
      let newvalues = Core.Map.find_exn !forward_map key in
      let () = self#remove_inverse_keys oldvalues in 
      self#add_inverse_values newvalues key      
  end
end 

(*
    method equal f ~other_fwd_map =
      Core.Map.equal f !forward_map !other_fwd_map *)

(*  UNBOUND 'e --- how to write these?
    method fold ~init ~f =
      Core.Map.fold !forward_map ~init ~f
    method fold_inverse ~init ~f =
      Core.Map.fold !reverse_map ~init ~f*)
(*
Cannot do these right now--type 'c the compraator is unbound
    method comparator () =
      Core.Map.comparator !forward_map
    method comparator_inverse () =
      Core.Map.comparator !reverse_map
*)
