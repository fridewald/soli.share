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
import soli/form/new_spending_form
import soli/pages
import soli/spending_store
import soli/web
import wisp.{type Request, type Response}

/// The HTTP request handler- your application!
///
pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  // Apply the middleware stack for this request/response.
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> get_home_page(req, ctx.subject)
    ["spending", "new"] -> create_spending(req, ctx.subject)
    ["spending", id, ..spending_path] ->
      handle_spending(req, id, spending_path, ctx)
    // This matches all other paths.
    _ -> wisp.not_found()
  }
}

fn handle_spending(
  req: request.Request(wisp.Connection),
  id: String,
  spending_path: List(String),
  ctx: web.Context,
) -> response.Response(wisp.Body) {
  let subject = ctx.subject
  case spending_path {
    [] -> get_spending_page(req, id, subject)
    ["pledge"] -> handle_pledge(req, id, subject)
    ["manage", key] -> get_manage_page(req, id, key, ctx)
    _ -> wisp.not_found()
  }
}

fn get_manage_page(
  req: request.Request(wisp.Connection),
  id: String,
  key: String,
  ctx: web.Context,
) -> response.Response(wisp.Body) {
  let sub = ctx.subject
  use <- wisp.require_method(req, http.Get)

  let spending = spending_store.get(sub, id)

  let html =
    case spending {
      Ok(spending) if spending.manage_key == key ->
        pages.manage(id, spending, ctx.hostname, key)
      Ok(_) -> todo
      Error(err) -> {
        echo err
        pages.not_found()
      }
    }
    |> element.to_document_string

  wisp.ok()
  |> wisp.html_body(html)
}

fn handle_pledge(
  req: Request,
  id: String,
  subject: Subject(spending_store.Message),
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
  sub: Subject(spending_store.Message),
) -> response.Response(wisp.Body) {
  use formdata <- wisp.require_form(req)

  let pledge_form =
    new_pledge_form.create_pledge_form()
    |> form.add_values(formdata.values)
  case form.run(pledge_form) {
    Ok(data) -> {
      case spending_store.add_pledge(sub, id, data) {
        Ok(_) ->
          wisp.redirect(to: "/spending/" <> id <> "/pledge" <> "/pledge_id")
        Error(spending_error) -> {
          io.println_error(
            "database error"
            <> spending_store.print_spending_error(spending_error),
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
  subject: Subject(spending_store.Message),
) -> Response {
  let html =
    case spending_store.get(subject, id) {
      Ok(spending) -> pages.pledge(form, spending)
      Error(err) -> {
        echo err
        pages.not_found()
      }
    }
    |> element.to_document_string

  wisp.ok()
  |> wisp.html_body(html)
}

fn create_spending(
  req: Request,
  sub: Subject(spending_store.Message),
) -> Response {
  use formdata <- wisp.require_form(req)

  let form =
    new_spending_form.create_spending_form()
    |> form.add_values(formdata.values)
  case form.run(form) {
    Ok(data) -> {
      let new_spending = spending_store.new(sub, data.amount_in_cent, data.name)
      case new_spending {
        Ok(spending) -> {
          wisp.redirect(
            to: "/spending/" <> spending.id <> "/manage/" <> spending.manage_key,
          )
        }
        Error(_) -> wisp.internal_server_error()
      }
    }
    Error(form) -> {
      let spendings = spending_store.get_spendings(sub)

      pages.index(form, unwrap_spendings(spendings))
      |> element.to_document_string
      |> wisp.html_response(422)
    }
  }
}

fn get_spending_page(
  req: Request,
  id: String,
  sub: Subject(spending_store.Message),
) -> Response {
  use <- wisp.require_method(req, http.Get)

  let spending = spending_store.get(sub, id)

  let html =
    case spending {
      Ok(spending) -> pages.spending(id, spending)
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
  sub: Subject(spending_store.Message),
) -> Response {
  use <- wisp.require_method(req, http.Get)
  // empty form
  let form = new_spending_form.create_spending_form()

  let spendings = spending_store.get_spendings(sub)

  let html =
    pages.index(form, unwrap_spendings(spendings))
    |> element.to_document_string

  wisp.ok()
  |> wisp.html_body(html)
}

fn unwrap_spendings(
  spendings: Result(List(spending_store.Spending), spending_store.SpendingError),
) -> List(spending_store.Spending) {
  spendings
  |> result.map_error(fn(er) {
    echo er
    er
  })
  |> result.unwrap(list.new())
}
