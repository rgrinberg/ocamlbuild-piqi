open Ocamlbuild_plugin

let piqi = "piqi"
let piqic = "piqic-ocaml"

let protobuf_include = "protobuf"

let piqi () =
  rule "piqi: .proto -> .piqi"
    ~dep:"%.proto"
    ~prod:"%.proto.piqi"
    begin fun env _build ->
      Cmd (S [ A piqi ; A "of-proto"
             ; A "-I"; P protobuf_include
             ; P (env "%.proto") ]
          )
    end;
  rule "piqi: .proto.piqi -> .ml"
    ~deps:["%.proto.piqi"; "*.proto"]
    ~prods:["%_piqi.ml"]
    begin fun env _build ->
      let piqi_file = env "%.proto.piqi" in
      (* piqi is buggy because it's generating the ml file relative to the cwd
         and not the source file (like it does for proto -> piqi) so we need
         to do some clean up after it *)
      let gen_piqi = Cmd (S [A piqic; P piqi_file]) in
      let needed_path = env "%_piqi.ml" in
      let fix_path = mv (Filename.basename needed_path) needed_path in
      Seq [gen_piqi ; fix_path ]
    end


let f = function
  | After_rules -> piqi ()
  | _ -> ()

let () = dispatch f
