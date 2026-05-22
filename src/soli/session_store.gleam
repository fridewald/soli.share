import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor.{type Next, type StartError, type Started, InitFailed}
import gleam/otp/supervision
import gleam/result
import parrot/dev
import soli/sql
import sqlight
import youid/uuid

pub type Session {
  Session(id: String, amount_in_cent: Int)
}

pub type SessionStore {
  SessionStore(connection: sqlight.Connection)
}

pub type SessionError {
  SqlError(sqlight.Error)
  GenericError
}

// dict.Dict(String, Session)

pub type Message {
  Get(reply_to: Subject(Result(Session, SessionError)), id: String)
  New(reply_to: Subject(String), amount_in_cent: Int)
}

pub fn new(sub: Subject(Message), amount_in_cent: Int) -> String {
  actor.call(sub, waiting: 20, sending: New(_, amount_in_cent))
}

pub fn get(sub: Subject(Message), id: String) {
  actor.call(sub, waiting: 20, sending: Get(_, id))
}

pub fn static_actor_child(
  name: process.Name(Message),
) -> supervision.ChildSpecification(Subject(Message)) {
  supervision.supervisor(fn() { start(name) })
}

fn start(
  name: process.Name(Message),
) -> Result(Started(Subject(Message)), StartError) {
  use connection <- result.try(
    sqlight.open("file:db/soli_share.sqlite3")
    |> result.map_error(fn(_) { InitFailed("") }),
  )
  actor.new(SessionStore(connection))
  |> actor.on_message(handle_message)
  |> actor.named(name)
  |> actor.start()
}

pub fn handle_message(
  session_store: SessionStore,
  message: Message,
) -> Next(SessionStore, Message) {
  case message {
    Get(reply_to, id) -> {
      // retrieve data and send back
      let #(sql, with, expecting) = sql.get_session(id:)
      let with = list.map(with, parrot_to_sqlight)
      let session =
        sqlight.query(
          sql,
          on: session_store.connection,
          with:,
          expecting: expecting,
        )
        |> result.map_error(SqlError)
        |> result.try(fn(res) {
          list.first(res) |> result.replace_error(GenericError)
        })
        |> result.map(get_session_to_session)

      actor.send(reply_to, session)
      actor.continue(session_store)
    }
    New(reply_to, amount_in_cent) -> {
      let id = uuid.v4_string()
      let #(sql, with, expecting) = sql.create_session(id:, amount_in_cent:)
      let with = list.map(with, parrot_to_sqlight)
      let _ =
        sqlight.query(
          sql,
          on: session_store.connection,
          with:,
          expecting: expecting,
        )
      actor.send(reply_to, id)
      actor.continue(session_store)
    }
  }
}

fn get_session_to_session(get_session: sql.GetSession) -> Session {
  Session(get_session.id, get_session.amount_in_cent)
}

fn parrot_to_sqlight(param: dev.Param) -> sqlight.Value {
  case param {
    dev.ParamBool(x) -> sqlight.bool(x)
    dev.ParamFloat(x) -> sqlight.float(x)
    dev.ParamInt(x) -> sqlight.int(x)
    dev.ParamString(x) -> sqlight.text(x)
    dev.ParamBitArray(x) -> sqlight.blob(x)
    dev.ParamNullable(x) -> sqlight.nullable(fn(a) { parrot_to_sqlight(a) }, x)
    dev.ParamList(_) -> panic as "sqlite does not implement lists"
    dev.ParamDate(_) -> panic as "date parameter needs to be implemented"
    dev.ParamTimestamp(_) -> panic as "sqlite does not support timestamps"
    dev.ParamDynamic(_) -> panic as "cannot process dynamic parameter"
  }
}
