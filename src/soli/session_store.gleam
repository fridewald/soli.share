import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option
import gleam/otp/actor.{type Next, type StartError, type Started, InitFailed}
import gleam/otp/supervision
import gleam/result
import parrot/dev
import soli/form/new_participation_form
import soli/sql
import sqlight
import youid/uuid

pub type Session {
  Session(
    id: String,
    amount_in_cent: Int,
    name: String,
    participation: List(Participation),
  )
}

pub type Participation

pub type SessionStore {
  SessionStore(connection: sqlight.Connection)
}

pub type SessionError {
  SqlError(sqlight.Error)
  GenericError
}

pub fn print_session_error(session_error: SessionError) {
  case session_error {
    SqlError(sql_err) ->
      "SqlError(code:"
      <> sql_err.code |> sqlight.error_code_to_int() |> int.to_string()
      <> ", message:"
      <> sql_err.message
      <> ")"
    GenericError -> "GenericError"
  }
}

pub type Message {
  Get(reply_to: Subject(Result(Session, SessionError)), id: String)
  GetSessions(reply_to: Subject(Result(List(Session), SessionError)))
  New(reply_to: Subject(String), amount_in_cent: Int, name: String)
  NewParticipation(
    reply_to: Subject(Result(Nil, SessionError)),
    id: String,
    amount_in_cent: Int,
    participant_name: String,
  )
}

pub fn new(sub: Subject(Message), amount_in_cent: Int, name: String) -> String {
  actor.call(sub, waiting: 20, sending: New(_, amount_in_cent, name))
}

pub fn get(sub: Subject(Message), id: String) -> Result(Session, SessionError) {
  actor.call(sub, waiting: 20, sending: Get(_, id))
}

pub fn get_sessions(
  sub: Subject(Message),
) -> Result(List(Session), SessionError) {
  actor.call(sub, waiting: 20, sending: GetSessions)
}

pub fn add_participant(
  sub: Subject(Message),
  id: String,
  data: new_participation_form.Participation,
) -> Result(Nil, SessionError) {
  actor.call(sub, waiting: 20, sending: NewParticipation(
    _,
    id:,
    amount_in_cent: data.amount_in_cent,
    participant_name: data.name,
  ))
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
    sqlight.open("file:db/soli.sqlite3")
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
    New(reply_to, amount_in_cent, name) -> {
      let id = uuid.v4_string()
      let #(sql, with, expecting) =
        sql.create_session(id:, amount_in_cent:, name: option.Some(name))
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
    GetSessions(reply_to:) -> {
      let #(sql, with, expecting) = sql.get_sessions()
      let with = list.map(with, parrot_to_sqlight)
      let sessions =
        sqlight.query(
          sql,
          on: session_store.connection,
          with:,
          expecting: expecting,
        )

      actor.send(
        reply_to,
        sessions
          |> result.map(list.map(_, get_sessions_to_session))
          |> result.map_error(SqlError),
      )
      actor.continue(session_store)
    }
    NewParticipation(reply_to:, id:, amount_in_cent:, participant_name:) -> {
      let #(sql, with) =
        sql.new_participation(
          id: "test",
          session_id: id,
          amount_in_cent:,
          participant_name: option.Some(participant_name),
        )

      let with = list.map(with, parrot_to_sqlight)
      let res =
        sqlight.query(
          sql,
          on: session_store.connection,
          with:,
          expecting: decode.dynamic,
        )
      actor.send(
        reply_to,
        res
          |> result.replace(Nil)
          |> result.map_error(SqlError),
      )
      actor.continue(session_store)
    }
  }
}

fn get_session_to_session(get_session: sql.GetSession) -> Session {
  Session(
    get_session.id,
    get_session.amount_in_cent,
    get_session.name |> option.unwrap(""),
    [],
  )
}

fn get_sessions_to_session(get_session: sql.GetSessions) -> Session {
  Session(
    get_session.id,
    get_session.amount_in_cent,
    get_session.name |> option.unwrap(""),
    [],
  )
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
