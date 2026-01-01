import gleam/erlang/process
import gleam/io
import mist
import soli/router
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

  let ctx = Context(static_directory: static_directory())

  let handler = router.handle_request(_, ctx)

  // Start the Mist web server.
  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  // The web server runs in new Erlang process, so put this one to sleep while
  // it works concurrently.
  process.sleep_forever()
}

pub fn static_directory() -> String {
  // The priv directory is where we store non-Gleam and non-Erlang files,
  // including static assets to be served.
  // This function returns an absolute path and works both in development and in
  // production after compilation.
  let assert Ok(priv_directory) = wisp.priv_directory("soli_share") |> echo

  priv_directory <> "/static"
}
