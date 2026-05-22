import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/int
import gleam/list
import gleam/result
import lustre/element
import soli/pages
import soli/session_store
import soli/web
import wisp.{type Request, type Response}

/// The HTTP request handler- your application!
///
pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  // Apply the middleware stack for this request/response.
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> home_page(req)
    ["share", "new"] -> create_new_share(req, ctx.subject)
    ["share", id] -> show_share(req, id, ctx.subject)
    // This matches all other paths.
    _ -> wisp.not_found()
  }
}

fn create_new_share(
  req: Request,
  sub: Subject(session_store.Message),
) -> Response {
  use formdata <- wisp.require_form(req)
  // use <- wisp.require_method(req, http.Post)
  let amount_result =
    list.key_find(formdata.values, "number") |> result.try(int.parse)
  case amount_result {
    Ok(amount) -> {
      let session_id = session_store.new(sub, amount)
      wisp.redirect(to: "/share/" <> session_id)
    }
    Error(_) -> wisp.bad_request("Invalid form fill in amount field")
  }
}

fn show_share(
  req: Request,
  id: String,
  sub: Subject(session_store.Message),
) -> Response {
  use <- wisp.require_method(req, http.Get)

  let session = session_store.get(sub, id)

  let html =
    case session {
      Ok(session) -> pages.share(id, session.amount_in_cent)
      Error(err) -> {
        echo err
        pages.not_found()
      }
    }
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
