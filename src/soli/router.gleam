import formal/form
import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/io
import gleam/list
import gleam/result
import lustre/element
import soli/form/new_participation_form
import soli/form/new_soli_session_form
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
    [] -> get_home_page(req, ctx.subject)
    ["share", "new"] -> create_new_share(req, ctx.subject)
    ["share", id] -> get_session_page(req, id, ctx.subject)
    ["share", id, "participate"] -> participate(req, id, ctx.subject)
    // This matches all other paths.
    _ -> wisp.not_found()
  }
}

fn participate(
  req: Request,
  id: String,
  subject: Subject(session_store.Message),
) -> response.Response(wisp.Body) {
  case req.method {
    http.Get -> {
      // empty form
      let form = new_participation_form.create_participate_form()
      get_participate(id, form, subject)
    }
    http.Post -> post_participate(req, id, subject)
    _ -> wisp.method_not_allowed(allowed: [http.Get, http.Post])
  }
}

fn post_participate(
  req: request.Request(wisp.Connection),
  id: String,
  sub: Subject(session_store.Message),
) -> response.Response(wisp.Body) {
  use formdata <- wisp.require_form(req)

  let participation_form =
    new_participation_form.create_participate_form()
    |> form.add_values(formdata.values)
  case form.run(participation_form) {
    Ok(data) -> {
      case session_store.add_participant(sub, id, data) {
        Ok(_) -> wisp.redirect(to: "/share/" <> id)
        Error(session_error) -> {
          io.println_error(
            "database error" <> session_store.print_session_error(session_error),
          )
          wisp.internal_server_error()
        }
      }
    }
    Error(form) -> get_participate(id, form, sub)
  }
}

fn get_participate(
  id: String,
  form: form.Form(new_participation_form.Participation),
  subject: Subject(session_store.Message),
) -> Response {
  let html =
    case session_store.get(subject, id) {
      Ok(session) -> pages.participate(form, session)
      Error(err) -> {
        echo err
        pages.not_found()
      }
    }
    |> element.to_document_string

  wisp.ok()
  |> wisp.html_body(html)
}

fn create_new_share(
  req: Request,
  sub: Subject(session_store.Message),
) -> Response {
  use formdata <- wisp.require_form(req)

  let form =
    new_soli_session_form.create_session_form()
    |> form.add_values(formdata.values)
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

fn get_session_page(
  req: Request,
  id: String,
  sub: Subject(session_store.Message),
) -> Response {
  use <- wisp.require_method(req, http.Get)

  let session = session_store.get(sub, id)

  let html =
    case session {
      Ok(session) -> pages.soli_session(id, session)
      Error(err) -> {
        echo err
        pages.not_found()
      }
    }
    |> element.to_document_string

  wisp.ok()
  |> wisp.html_body(html)
}

fn get_home_page(
  req: Request,
  sub: Subject(session_store.Message),
) -> Response {
  use <- wisp.require_method(req, http.Get)
  // empty form
  let form = new_soli_session_form.create_session_form()

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
