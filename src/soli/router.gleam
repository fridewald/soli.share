import formal/form
import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/io
import gleam/list
import gleam/result
import lustre/element
import soli/form/new_pledge_form
import soli/form/new_spend_form
import soli/pages
import soli/spend_store
import soli/web
import wisp.{type Request, type Response}

/// The HTTP request handler- your application!
///
pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  // Apply the middleware stack for this request/response.
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> get_home_page(req, ctx.subject)
    ["share", "new"] -> create_spend(req, ctx.subject)
    ["share", id] -> get_spend_page(req, id, ctx.subject)
    ["share", id, "pledge"] -> pledge(req, id, ctx.subject)
    // This matches all other paths.
    _ -> wisp.not_found()
  }
}

fn pledge(
  req: Request,
  id: String,
  subject: Subject(spend_store.Message),
) -> response.Response(wisp.Body) {
  case req.method {
    http.Get -> {
      // empty form
      let form = new_pledge_form.create_pledge_form()
      get_pledge(id, form, subject)
    }
    http.Post -> post_pledge(req, id, subject)
    _ -> wisp.method_not_allowed(allowed: [http.Get, http.Post])
  }
}

fn post_pledge(
  req: request.Request(wisp.Connection),
  id: String,
  sub: Subject(spend_store.Message),
) -> response.Response(wisp.Body) {
  use formdata <- wisp.require_form(req)

  let pledge_form =
    new_pledge_form.create_pledge_form()
    |> form.add_values(formdata.values)
  case form.run(pledge_form) {
    Ok(data) -> {
      case spend_store.add_pledge(sub, id, data) {
        Ok(_) -> wisp.redirect(to: "/share/" <> id)
        Error(spend_error) -> {
          io.println_error(
            "database error" <> spend_store.print_spend_error(spend_error),
          )
          wisp.internal_server_error()
        }
      }
    }
    Error(form) -> get_pledge(id, form, sub)
  }
}

fn get_pledge(
  id: String,
  form: form.Form(new_pledge_form.Pledge),
  subject: Subject(spend_store.Message),
) -> Response {
  let html =
    case spend_store.get(subject, id) {
      Ok(spend) -> pages.pledge(form, spend)
      Error(err) -> {
        echo err
        pages.not_found()
      }
    }
    |> element.to_document_string

  wisp.ok()
  |> wisp.html_body(html)
}

fn create_spend(req: Request, sub: Subject(spend_store.Message)) -> Response {
  use formdata <- wisp.require_form(req)

  let form =
    new_spend_form.create_spend_form()
    |> form.add_values(formdata.values)
  case form.run(form) {
    Ok(data) -> {
      let spend_id = spend_store.new(sub, data.amount_in_cent, data.name)
      wisp.redirect(to: "/share/" <> spend_id)
    }
    Error(form) -> {
      let spends = spend_store.get_spends(sub)

      pages.index(form, unwrap_spends(spends))
      |> element.to_document_string
      |> wisp.html_response(422)
    }
  }
}

fn get_spend_page(
  req: Request,
  id: String,
  sub: Subject(spend_store.Message),
) -> Response {
  use <- wisp.require_method(req, http.Get)

  let spend = spend_store.get(sub, id)

  let html =
    case spend {
      Ok(spend) -> pages.spend(id, spend)
      Error(err) -> {
        echo err
        pages.not_found()
      }
    }
    |> element.to_document_string

  wisp.ok()
  |> wisp.html_body(html)
}

fn get_home_page(req: Request, sub: Subject(spend_store.Message)) -> Response {
  use <- wisp.require_method(req, http.Get)
  // empty form
  let form = new_spend_form.create_spend_form()

  let spends = spend_store.get_spends(sub)

  let html =
    pages.index(form, unwrap_spends(spends))
    |> element.to_document_string

  wisp.ok()
  |> wisp.html_body(html)
}

fn unwrap_spends(
  spends: Result(List(spend_store.Spend), spend_store.SpendError),
) -> List(spend_store.Spend) {
  spends
  |> result.map_error(fn(er) {
    echo er
    er
  })
  |> result.unwrap(list.new())
}
