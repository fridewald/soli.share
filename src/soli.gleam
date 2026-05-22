import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import gleam/otp/static_supervisor.{type Supervisor} as supervisor
import mist
import soli/router
import soli/session_store
import soli/web.{Context}
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  io.println("Hello from soli_share!")

  // Wisp Setup
  wisp.configure_logger()
  // Here we generate a secret key, but in a real application you would want to
  // load this from somewhere so that it is not regenerated on every restart.
  let secret_key_base = wisp.random_string(64)

  let process_name = process.new_name("session_store")
  let subject = process.named_subject(process_name)

  let _ = start_supervisor(process_name)

  let ctx = Context(static_directory: static_directory(), subject:)

  let handler = router.handle_request(_, ctx)

  // Start the Mist web server.
  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}

fn start_supervisor(
  process_name: process.Name(session_store.Message),
) -> actor.StartResult(Supervisor) {
  supervisor.new(supervisor.OneForOne)
  |> supervisor.add(session_store.static_actor_child(process_name))
  |> supervisor.start()
}

pub fn static_directory() -> String {
  // The priv directory is where we store non-Gleam and non-Erlang files,
  // including static assets to be served.
  // This function returns an absolute path and works both in development and in
  // production after compilation.
  let assert Ok(priv_directory) = wisp.priv_directory("soli")

  priv_directory <> "/static"
}
