import formal/form
import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/list
import gleam/result
import lustre/element
import soli/form as soli_form
import soli/pages
import soli/participate_form
import soli/session_store
import soli/web
import wisp.{type Request, type Response}

/// The HTTP request handler- your application!
///
pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  // Apply the middleware stack for this request/response.
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> home_page(req, ctx.subject)
    ["share", "new"] -> create_new_share(req, ctx.subject)
    ["share", id] -> show_share(req, id, ctx.subject)
    ["share", id, "participate"] -> participate(req, id, ctx.subject)
    // This matches all other paths.
    _ -> wisp.not_found()
  }
}

fn participate(
  req: Request,
  id: String,
  subject: Subject(session_store.Message),
) -> Response {
  use <- wisp.require_method(req, http.Get)

  let session = session_store.get(subject, id)

  let html =
    case session {
      Ok(session) -> pages.participate(session)
      Error(err) -> {
        echo err
        pages.not_found()
      }
    }
    |> element.to_document_string

  wisp.created()
  |> wisp.html_body(html)
}

fn create_new_share(
  req: Request,
  sub: Subject(session_store.Message),
) -> Response {
  use formdata <- wisp.require_form(req)
  let form = soli_form.create_session_form() |> form.add_values(formdata.values)
  case form.run(form) {
    Ok(data) -> {
      let session_id = session_store.new(sub, data.amount_in_cent, data.name)
      wisp.redirect(to: "/share/" <> session_id)
    }
    Error(form) -> {
      let sessions = session_store.get_sessions(sub)

      pages.index(form, unwrap_sessions(sessions))
      |> element.to_document_string
      |> wisp.html_response(422)
    }
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
      Ok(session) -> pages.share(id, session)
      Error(err) -> {
        echo err
        pages.not_found()
      }
    }
    |> element.to_document_string

  wisp.created()
  |> wisp.html_body(html)
}

fn home_page(req: Request, sub: Subject(session_store.Message)) -> Response {
  use <- wisp.require_method(req, http.Get)
  // empty form
  let form = soli_form.create_session_form()

  let sessions = session_store.get_sessions(sub)

  let html =
    pages.index(form, unwrap_sessions(sessions))
    |> element.to_document_string

  wisp.ok()
  |> wisp.html_body(html)
}

fn unwrap_sessions(
  sessions: Result(List(session_store.Session), session_store.SessionError),
) -> List(session_store.Session) {
  sessions
  |> result.map_error(fn(er) {
    echo er
    er
  })
  |> result.unwrap(list.new())
}
