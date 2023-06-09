(*
  Plans:
    - Implement a basic DB, maybe PostgreSQL
    - Configure a simple Twitter clone template
    - Wire htmx to handle all the logic
      - Tweet container to poll for new tweets from the DB 
      - Tweet button stores text content and resets form 
      - Accessible from multuple browser tabs simultaneously
 *)

(* Am I supposed to break these out into separate files eventually? *)
(* It does seem like these list of routes could get enormous *)
(* Maybe there is a need to move to dynamic routes? *)
let pages = [
  (* Handler methodology - use a handler and a type to generate pages at the root *)
  Dream.get "/" (fun request ->
    let%lwt page = (Handler.generate_page Feed request) in
    Dream.html page
  ) ;

  Dream.get "/hello" (fun request ->
    let%lwt page = (Handler.generate_page Hello request) in
    Dream.html page
  ) ;
]

(* The below "fragments" are page pieces that can be hot swapped out with htmx *)
let fragments = [
  Dream.get "/posts" (fun request ->
    let%lwt posts = Dream.sql request (Database.query_posts ()) in
    match posts with
    | Ok (posts) -> Dream.html (Builder.compile_elt (Builder.list_posts posts))
    | _ -> Dream.response (Builder.error_page ()) |> Lwt.return
  ) ;

  Dream.get "/colorize" (fun _ ->
    Dream.html (Builder.compile_elt (Builder.create_fancy_div ()))
  ) ;
]

let actions = [
  Dream.post "/posts" (fun request ->
    let%lwt posts = Dream.sql request (Database.query_posts ()) in
    match posts with
    | Ok (posts) -> Dream.html (Builder.compile_elt (Builder.list_posts posts))
    | _ -> Dream.response (Builder.error_page ()) |> Lwt.return
  );
]

let () =
  (*
  let open Lwt_result.Syntax in
  let uri = Uri.of_string "postgresql://localhost/mydatabase" in
    match Caqti_lwt.connect uri with
      | Error err -> Lwt_io.printlf "Error: %s" (Caqti_error.show err)
      | Ok conn -> do_something_with conn

  let* conn = Caqti_lwt.connect (Uri.of_string "postgresql://dream:password@localhost:5432/whnvr") in
  let* () =
      Petrol.VersionedSchema.initialise
        DB.db conn in
*)
  (* <-- Uncomment these lines to continue wiring Petrol into the main startup function of the server (for migrations)
  let () = Lwt_main.run (
    let open Lwt_result.Syntax in
    let* conn = Caqti_lwt.connect url in
    let* () = Petrol.VersionedSchema.initialise Database.schema conn in
    Lwt.return ()
  ) in
  *)
  Dream.run ~interface:"0.0.0.0"
  @@ Dream.logger
  (* George, if you read this, I promise this is not a password I'm really using, please don't fire me. *)
  @@ Dream.sql_pool "postgresql://dream:password@localhost:5432/whnvr"
  @@ Dream.sql_sessions
  @@ Dream.router (
    pages @
    fragments @
    actions @
    [
      (* Serve any static content we may need, maybe stylesheets? *)
      (* This local_directory path is relative to the location the app is run from *)
      Dream.get "/static/**" @@ Dream.static "www/static" ;
    ]
  )
