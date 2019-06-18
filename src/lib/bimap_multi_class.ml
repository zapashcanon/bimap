module Bimap_pure = Bimap_multi_module.Bimap_multi_module
module Bimap_multi_class (ModuleA : Map.S)(ModuleB : Map.S) = struct
  module Bimap_p = Bimap_pure(ModuleA)(ModuleB)
  class bimap_multi_class = object(self)
    val mutable forward_map = ref ModuleA.empty
    val mutable reverse_map = ref ModuleB.empty
    method private empty_forward_map () =
      forward_map := ModuleA.empty
    method private empty_reverse_map () =
      reverse_map := ModuleB.empty

    method add_multi ~key ~data =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.add newt ~key ~data in
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method add_multi_reverse ~key ~data =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.add_reverse newt ~key ~data in
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method bindings () =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      Bimap_p.bindings newt
    method bindings_reverse () =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      Bimap_p.bindings_reverse newt
                       
    method private create_reverse_map_from_forward_map () =
      let newrevmap = Bimap_p.create_reverse_map_from_forward_map !forward_map in
      reverse_map := newrevmap

    method private create_forward_map_from_reverse_map () =
      let newfwdmap = Bimap_p.create_forward_map_from_reverse_map !reverse_map in
      forward_map := newfwdmap

    method cardinal () =
      ModuleA.cardinal !forward_map
    method cardinal_reverse () =
      ModuleB.cardinal !reverse_map
    method choose () =
      ModuleA.choose !forward_map
    method choose_reverse () =
      ModuleB.choose !reverse_map
    method compare f ~othermap =
      ModuleA.compare f !forward_map othermap
    method compare_reverse f ~othermap =
      ModuleB.compare f !reverse_map othermap
    method empty () =
      let () = self#empty_forward_map () in
      self#empty_reverse_map ()
    method equal f ~othermap =
      ModuleA.equal f !forward_map othermap
    method equal_reverse f ~othermap =
      ModuleB.equal f !reverse_map othermap
    method exists ~f =
      ModuleA.exists f !forward_map
    method exists_reverse ~f =
      ModuleB.exists f !reverse_map
    method find ~key =
      ModuleA.find key !forward_map
    method find_reverse ~key =
      ModuleB.find key !reverse_map
    method find_opt ~key =
      try
        Some (ModuleA.find key !forward_map)
      with _ -> None 
    method find_reverse_opt ~key =
      try
        Some (ModuleB.find key !reverse_map)
      with _ -> None
    method filter ~f =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.filter newt ~f in
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method filter_reverse ~f =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.filter_reverse newt ~f in
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method fold : 'e. (ModuleA.key -> ModuleB.key list -> 'e -> 'e) -> 'e -> 'e =
      (fun f init ->
        let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
        Bimap_p.fold newt ~f init)
    method fold_reverse : 'e. (ModuleB.key -> ModuleA.key list -> 'e -> 'e) -> 'e -> 'e =
      (fun f init ->
        let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in 
        Bimap_p.fold_reverse newt ~f init)
    method for_all ~f =
      ModuleA.for_all f !forward_map
    method for_all_reverse ~f =
      ModuleB.for_all f !reverse_map
    method is_empty =
      ModuleA.is_empty !forward_map
    method iter ~f =
      ModuleA.iter f !forward_map
    method iter_reverse ~f =
      ModuleB.iter f !reverse_map
    method map ~f =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.map ~f newt in
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method map_reverse ~f =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.map_reverse ~f newt in
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method mapi ~f =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.mapi ~f newt in
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method mapi_reverse ~f =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.mapi_reverse ~f newt in
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method min_binding =
      ModuleA.min_binding !forward_map
    method min_binding_reverse =
      ModuleB.min_binding !reverse_map
    method max_binding =
      ModuleA.max_binding !forward_map
    method max_binding_reverse =
      ModuleB.max_binding !reverse_map
    method mem key =
      ModuleA.mem key !forward_map
    method mem_reverse key =
      ModuleB.mem key !reverse_map
    method merge f ~(othermap:ModuleB.key list ModuleA.t) =
      let () = forward_map := ModuleA.merge f !forward_map othermap in
      self#create_reverse_map_from_forward_map ()
    method merge_reverse f ~(othermap:ModuleA.key list ModuleB.t) =
      let () = reverse_map := ModuleB.merge f !reverse_map othermap in
      self#create_forward_map_from_reverse_map ()
    method partition ~f =
      ModuleA.partition f !forward_map
    method partition_reverse ~f =
      ModuleB.partition f !reverse_map
    method remove ~key =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.remove newt ~key in 
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method remove_reverse ~key =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.remove_reverse newt ~key in 
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    (**Remove the head element*)
    method remove_multi_opt ~key =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let result = Bimap_p.remove_multi newt ~key in
      match result with
      | Some (newt, value) -> 
        let () = forward_map := Bimap_p.get_forward_map newt in
        let () = reverse_map := Bimap_p.get_reverse_map newt in
        Some value
      | None -> None
    method remove_reverse_multi_opt ~key =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let result = Bimap_p.remove_multi_reverse newt ~key in
      match result with
      | Some (newt, value) -> 
        let () = forward_map := Bimap_p.get_forward_map newt in
        let () = reverse_map := Bimap_p.get_reverse_map newt in
        Some value
      | None -> None
    method split ~key =
      ModuleA.split key !forward_map
    method split_reverse ~key =
      ModuleB.split key !reverse_map
    method update ~key ~f =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.update newt ~key ~f in
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method update_reverse ~key ~f =
      let newt = Bimap_p.create_t ~fwdmap:!forward_map ~revmap:!reverse_map in
      let newt = Bimap_p.update_reverse newt ~key ~f in 
      let () = forward_map := Bimap_p.get_forward_map newt in
      reverse_map := Bimap_p.get_reverse_map newt
    method singleton ~key ~data =
      let () = self#empty_forward_map () in
      let () = self#empty_reverse_map () in
      self#add_multi ~key ~data
    method singleton_reverse ~key ~data =
      let () = self#empty_forward_map () in
      let () = self#empty_reverse_map () in
      self#add_multi_reverse ~key ~data
    method union f ~(othermap:ModuleB.key list ModuleA.t) =
      let () = forward_map := ModuleA.union f !forward_map othermap in
      self#create_reverse_map_from_forward_map ()
    method union_reverse f ~(othermap:ModuleA.key list ModuleB.t) =
      let () = reverse_map := ModuleB.union f !reverse_map othermap in
      self#create_forward_map_from_reverse_map ()
  end
end
