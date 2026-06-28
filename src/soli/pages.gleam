import formal/form.{type Form}
import gleam/float
import gleam/int
import gleam/list
import hx
import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html
import lustre/element/keyed
import soli/form/new_participation_form
import soli/form/new_soli_session_form
import soli/session_store

fn body(elements: List(element.Element(a))) -> element.Element(a) {
  html.html([attribute.lang("en")], [
    head(),
    html.header([], [
      html.div([attribute.class("container")], [
        html.a([attribute.href("/")], [
          html.h3([], [html.text("Soli")]),
        ]),
      ]),
    ]),
    html.body([], elements),
    html.footer([], []),
  ])
}

fn head() -> element.Element(a) {
  html.head([], [
    html.meta([attribute.charset("utf-8")]),
    html.meta([
      attribute.content("width=device-width, initial-scale=1"),
      attribute.name("viewport"),
    ]),
    html.meta([attribute.content("light"), attribute.name("color-scheme")]),
    //  * 204 No Content by default does nothing, but is not an error
    //  * 2xx, 3xx and 422 responses are non-errors and are swapped
    //  * 4xx & 5xx responses are not swapped and are errors
    //  * all other responses are swapped using "..." as a catch-all
    html.meta([
      attribute.name("htmx-config"),
      attribute.content(
        "{
            \"responseHandling\":[
                {\"code\":\"204\", \"swap\": false},
                {\"code\":\"[23]..\", \"swap\": true},
                {\"code\":\"422\", \"swap\": true},
                {\"code\":\"[45]..\", \"swap\": false, \"error\":true},
                {\"code\":\"...\", \"swap\": true}
            ]
        }",
      ),
    ]),
    html.link([
      attribute.href("/static/pico.pink.css"),
      attribute.rel("stylesheet"),
    ]),
    html.script([attribute.src("/static/htmx.min.js")], ""),
    html.title([], "Soli"),
  ])
}

fn main(main_element: List(element.Element(a))) -> element.Element(a) {
  body([
    html.main([attribute.id("main"), attribute.class("container")], [
      // [],
      html.nav([], [
        // html.ul([], [html.li([], [html.strong([], [html.text("Soli")])])]),
      // html.ul([], []),
      // html.ul([], [
      //   html.li([], [
      //     html.a([attribute.href("/")], [html.text("Home")]),
      //   ]),
      // ]),
      ]),
      ..main_element
    ]),
  ])
}

pub fn index(
  form: Form(new_soli_session_form.CreateSession),
  sessions: List(session_store.Session),
) {
  main([
    html.hgroup([], [
      html.p([], [
        html.text("Split group costs in a "),
        html.em([], [html.text("pay what you think")]),
        html.text(" approach"),
      ]),
    ]),
    html.hr([]),
    html.form([], [
      field_input(
        form,
        new_soli_session_form.name_field_name,
        kind: "text",
        label: " Name ",
        attributes: [
          attribute("aria-label", "Session name"),
          attribute.placeholder("Name"),
          attribute.required(True),
        ],
      ),
      field_input(
        form,
        new_soli_session_form.amount_in_cent_field_name,
        kind: "number",
        label: " Amount in €",
        attributes: [
          attribute("aria-label", "Amount in cent"),
          attribute.placeholder("0.00 €"),
          attribute.required(True),
          attribute.min("0"),
          attribute.step("0.01"),
        ],
      ),
      html.button(
        [
          hx.push_url(True),
          hx.select("#main"),
          hx.target(hx.Selector("#main")),
          hx.post("/share/new"),
        ],
        [html.text(" Create soli share session ")],
      ),
    ]),
    html.hr([]),
    keyed.ul(
      [],
      list.map(sessions, fn(session) {
        let session_data = session
        #(
          session.id,
          html.li([], [
            html.text("Name: "),
            html.strong([], [html.text(session_data.name)]),
            html.text(" Id: "),
            html.a([attribute.href("/share/" <> session_data.id)], [
              html.text(session_data.id),
            ]),
            html.text(
              " Amount: "
              <> float.to_string(
                int.to_float(session_data.amount_in_cent) /. 100.0,
              )
              <> " €",
            ),
          ]),
        )
      }),
    ),
  ])
}

fn field_input(
  form: Form(t),
  name name: String,
  kind kind: String,
  label label_text: String,
  attributes attributes: List(attribute.Attribute(a)),
) -> element.Element(a) {
  let errors = form.field_error_messages(form, name) |> echo

  html.label([], [
    // The label text, for the user to read
    html.text(label_text),
    // The input, for the user to type into
    html.input([
      attribute.type_(kind),
      attribute.name(name),
      attribute.value(form.field_value(form, name)),
      case errors {
        [] -> attribute.none()
        _ -> attribute.aria_invalid("true")
      },
      ..attributes
    ]),
    // Any errors presented below
    ..list.map(errors, fn(msg) { html.small([], [element.text(msg)]) })
  ])
}

pub fn soli_session(id: String, session: session_store.Session) {
  main([
    html.hgroup([], [
      html.h1([], [html.text("Soli ")]),
      html.h3([], [html.text("Name: " <> session.name)]),
      html.p([], [
        html.text(
          "Split "
          <> float.to_string(int.to_float(session.amount_in_cent) /. 100.0)
          <> " €",
        ),
      ]),
    ]),
    html.hr([]),
    html.button(
      [
        hx.push_url(True),
        hx.get("/share/" <> id <> "/participate"),
        hx.select("#main"),
        hx.target(hx.Selector("#main")),
      ],
      [
        html.text("Participate"),
      ],
    ),
    // html.p([], [html.strong([], [html.text("Id: ")]), html.text(id)]),
  ])
}

pub fn participate(
  form: Form(new_participation_form.Participation),
  session: session_store.Session,
) {
  main([
    html.hgroup([], [
      html.text("Want to participate in " <> session.name <> "?"),
    ]),
    html.form([], [
      field_input(
        form,
        new_soli_session_form.name_field_name,
        kind: "text",
        label: " Name ",
        attributes: [
          attribute("aria-label", "Your name"),
          attribute.placeholder("Your name"),
          attribute.required(True),
        ],
      ),
      field_input(
        form,
        new_soli_session_form.amount_in_cent_field_name,
        kind: "number",
        label: " Amount in €",
        attributes: [
          attribute("aria-label", "Amount in cent"),
          attribute.placeholder("0.00 €"),
          attribute.required(True),
          attribute.min("0"),
          attribute.step("0.01"),
        ],
      ),
      html.button(
        [
          hx.push_url(True),
          hx.select("#main"),
          hx.target(hx.Selector("#main")),
          hx.post("/share/" <> session.id <> "/participate"),
        ],
        [html.text(" Participate in \"" <> session.name <> "\"")],
      ),
    ]),
  ])
}

pub fn not_found() {
  main([
    html.hgroup([], [
      html.h1([], [html.text("Not found")]),
    ]),
  ])
}
