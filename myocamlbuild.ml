open Ocamlbuild_plugin

let piqi = "piqi"
let piqic = "piqic-ocaml"

let protobuf_include = "protobuf"

let piqi () =
  pdep [piqi] "import" (fun s -> [ protobuf_include / s^".proto.piqi"]) ;

  let dep = "%.proto" in
  let prod = "%.proto.piqi" in
  rule "piqi: .proto -> .piqi" ~dep ~prod
    begin fun env build ->
      let file = env dep in
      let out = env prod in
      let tags = tags_of_pathname out ++ piqi in
      Cmd (S [ A piqi ; A "of-proto"
             ; A "-I"; P protobuf_include
             ; A "-o"; P out
             ; P file ; T tags ]
          )
    end;
  rule "piqi: .proto.piqi -> .ml"
    ~deps:["%.proto.piqi"]
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
