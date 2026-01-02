import gleam/int
import hx
import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html

pub fn index() {
  html.html([attribute.lang("en")], [
    head(),
    html.body([hx.boost(True)], [
      html.main([attribute.id("main"), attribute.class("container")], [
        html.hgroup([], [
          html.h1([], [html.text("Soli share")]),
          html.p([], [
            html.text("Split group costs in a "),
            html.em([], [html.text("pay what you think")]),
            html.text(" approach"),
          ]),
        ]),
        html.form([], [
          html.label([], [
            html.text(" Amount "),
            html.input([
              attribute("aria-label", "Number"),
              attribute.placeholder("Amount"),
              attribute.name("number"),
              attribute.type_("number"),
            ]),
          ]),
          html.button(
            [
              hx.push_url(True),
              hx.include(hx.CssSelector("#main")),
              hx.target(hx.CssSelector("#main")),
              hx.post("/share/new"),
            ],
            [html.text(" Create soli share ")],
          ),
        ]),
      ]),
    ]),
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
    html.link([
      attribute.href("/static/pico.pink.css"),
      attribute.rel("stylesheet"),
    ]),
    html.script([attribute.src("/static/htmx.min.js")], ""),
    html.title([], "Soli share"),
  ])
}

pub fn share(id: String, amount: Int) {
  html.html([attribute.lang("en")], [
    head(),
    html.body([hx.boost(True)], [
      html.main([attribute.id("main"), attribute.class("container")], [
        html.hgroup([], [
          html.h1([], [html.text("New soli share created")]),
          html.p([], [html.text("Split group " <> int.to_string(amount))]),
        ]),
        html.p([], [html.strong([], [html.text("Id: ")]), html.text(id)]),
      ]),
    ]),
  ])
}
