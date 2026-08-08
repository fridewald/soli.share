import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option
import gleam/otp/actor.{type Next, type StartError, type Started, InitFailed}
import gleam/otp/supervision
import gleam/result
import parrot/dev
import soli/form/new_pledge_form
import soli/sql
import sqlight
import youid/uuid

pub type Spend {
  Spend(id: String, amount_in_cent: Int, name: String, pledges: List(Pledge))
}

pub type Pledge

pub type SpendStore {
  SpendStore(connection: sqlight.Connection)
}

pub type SpendError {
  SqlError(sqlight.Error)
  GenericError
}

pub fn print_spend_error(spend_error: SpendError) {
  case spend_error {
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
  Get(reply_to: Subject(Result(Spend, SpendError)), id: String)
  GetSpends(reply_to: Subject(Result(List(Spend), SpendError)))
  New(reply_to: Subject(String), amount_in_cent: Int, name: String)
  NewPledge(
    reply_to: Subject(Result(Nil, SpendError)),
    id: String,
    amount_in_cent: Int,
    participant_name: String,
  )
}

pub fn new(sub: Subject(Message), amount_in_cent: Int, name: String) -> String {
  actor.call(sub, waiting: 20, sending: New(_, amount_in_cent, name))
}

pub fn get(sub: Subject(Message), id: String) -> Result(Spend, SpendError) {
  actor.call(sub, waiting: 20, sending: Get(_, id))
}

pub fn get_spends(sub: Subject(Message)) -> Result(List(Spend), SpendError) {
  actor.call(sub, waiting: 20, sending: GetSpends)
}

pub fn add_pledge(
  sub: Subject(Message),
  id: String,
  data: new_pledge_form.Pledge,
) -> Result(Nil, SpendError) {
  actor.call(sub, waiting: 20, sending: NewPledge(
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
  actor.new(SpendStore(connection))
  |> actor.on_message(handle_message)
  |> actor.named(name)
  |> actor.start()
}

pub fn handle_message(
  spend_store: SpendStore,
  message: Message,
) -> Next(SpendStore, Message) {
  case message {
    Get(reply_to, id) -> {
      // retrieve data and send back
      let #(sql, with, expecting) = sql.get_spend(id:)
      let with = list.map(with, parrot_to_sqlight)
      let spend =
        sqlight.query(
          sql,
          on: spend_store.connection,
          with:,
          expecting: expecting,
        )
        |> result.map_error(SqlError)
        |> result.try(fn(res) {
          list.first(res) |> result.replace_error(GenericError)
        })
        |> result.map(get_spend_to_spend)

      actor.send(reply_to, spend)
      actor.continue(spend_store)
    }
    New(reply_to, amount_in_cent, name) -> {
      let id = uuid.v4_string()
      let #(sql, with, expecting) =
        sql.create_spend(id:, amount_in_cent:, name: option.Some(name))
      let with = list.map(with, parrot_to_sqlight)
      let _ =
        sqlight.query(
          sql,
          on: spend_store.connection,
          with:,
          expecting: expecting,
        )
      actor.send(reply_to, id)
      actor.continue(spend_store)
    }
    GetSpends(reply_to:) -> {
      let #(sql, with, expecting) = sql.get_spends()
      let with = list.map(with, parrot_to_sqlight)
      let spends =
        sqlight.query(
          sql,
          on: spend_store.connection,
          with:,
          expecting: expecting,
        )

      actor.send(
        reply_to,
        spends
          |> result.map(list.map(_, get_spends_to_spend))
          |> result.map_error(SqlError),
      )
      actor.continue(spend_store)
    }
    NewPledge(reply_to:, id:, amount_in_cent:, participant_name:) -> {
      let #(sql, with) =
        sql.new_pledge(
          id: "test",
          session_id: id,
          amount_in_cent:,
          participant_name: option.Some(participant_name),
        )

      let with = list.map(with, parrot_to_sqlight)
      let res =
        sqlight.query(
          sql,
          on: spend_store.connection,
          with:,
          expecting: decode.dynamic,
        )
      actor.send(
        reply_to,
        res
          |> result.replace(Nil)
          |> result.map_error(SqlError),
      )
      actor.continue(spend_store)
    }
  }
}

fn get_spend_to_spend(get_spend: sql.GetSpend) -> Spend {
  Spend(
    get_spend.id,
    get_spend.amount_in_cent,
    get_spend.name |> option.unwrap(""),
    [],
  )
}

fn get_spends_to_spend(get_spend: sql.GetSpends) -> Spend {
  Spend(
    get_spend.id,
    get_spend.amount_in_cent,
    get_spend.name |> option.unwrap(""),
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
