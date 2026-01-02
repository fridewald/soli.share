import gleam/http
import lustre/element
import soli/pages
import soli/web
import wisp.{type Request, type Response}

/// The HTTP request handler- your application!
///
pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  // Apply the middleware stack for this request/response.
  use req <- web.middleware(req, ctx)

  // Wisp doesn't have a special router abstraction, instead we recommend using
  // regular old pattern matching. This is faster than a router, is type safe,
  // and means you don't have to learn or be limited by a special DSL.
  //
  case wisp.path_segments(req) {
    // This matches `/`.
    [] -> home_page(req)
    ["share", "new"] -> create_new_share(req)
    ["share", id] -> show_share(req, id)

    // [name] -> home_page(req, name)
    // This matches all other paths.
    _ -> wisp.not_found()
  }
}

fn create_new_share(req: Request) -> Response {
  use <- wisp.require_method(req, http.Post)
  wisp.redirect(to: "/share/100")
}

fn show_share(req: Request, id: String) -> Response {
  use <- wisp.require_method(req, http.Get)
  echo req

  let html =
    pages.share(id, 100)
    |> element.to_document_string

  wisp.created()
  |> wisp.html_body(html)
}

fn home_page(req: Request) -> Response {
  use <- wisp.require_method(req, http.Get)
  let html =
    pages.index()
    |> element.to_document_string

  wisp.ok()
  |> wisp.html_body(html)
}
