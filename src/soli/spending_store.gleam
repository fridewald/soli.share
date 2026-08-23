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

pub type Spending {
  Spending(
    id: String,
    amount_in_cent: Int,
    name: String,
    pledges: List(Pledge),
    manage_key: String,
  )
}

pub type Pledge

pub type SpendingStore {
  SpendingStore(connection: sqlight.Connection)
}

pub type SpendingError {
  SqlError(sqlight.Error)
  GenericError
}

pub fn print_spending_error(spending_error: SpendingError) {
  case spending_error {
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
  Get(reply_to: Subject(Result(Spending, SpendingError)), id: String)
  GetSpendings(reply_to: Subject(Result(List(Spending), SpendingError)))
  New(reply_to: Subject(Result(Spending, SpendingError)), amount_in_cent: Int, name: String)
  NewPledge(
    reply_to: Subject(Result(Nil, SpendingError)),
    id: String,
    amount_in_cent: Int,
    participant_name: String,
  )
}

pub fn new(
  sub: Subject(Message),
  amount_in_cent: Int,
  name: String,
) -> Result(Spending, SpendingError) {
  actor.call(sub, waiting: 20, sending: New(_, amount_in_cent, name))
}

pub fn get(
  sub: Subject(Message),
  id: String,
) -> Result(Spending, SpendingError) {
  actor.call(sub, waiting: 20, sending: Get(_, id))
}

pub fn get_spendings(
  sub: Subject(Message),
) -> Result(List(Spending), SpendingError) {
  actor.call(sub, waiting: 20, sending: GetSpendings)
}

pub fn add_pledge(
  sub: Subject(Message),
  id: String,
  data: new_pledge_form.Pledge,
) -> Result(Nil, SpendingError) {
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
  actor.new(SpendingStore(connection))
  |> actor.on_message(handle_message)
  |> actor.named(name)
  |> actor.start()
}

pub fn handle_message(
  spending_store: SpendingStore,
  message: Message,
) -> Next(SpendingStore, Message) {
  case message {
    Get(reply_to, id) -> {
      // retrieve data and send back
      let #(sql, with, expecting) = sql.get_spending(id:)
      let with = list.map(with, parrot_to_sqlight)
      let spending =
        sqlight.query(
          sql,
          on: spending_store.connection,
          with:,
          expecting: expecting,
        )
        |> result.map_error(SqlError)
        |> result.try(fn(res) {
          list.first(res) |> result.replace_error(GenericError)
        })
        |> result.map(get_spending_to_spending)

      actor.send(reply_to, spending)
      actor.continue(spending_store)
    }
    New(reply_to, amount_in_cent, name) -> {
      let id = uuid.v4_string()
      let manage_key = uuid.v4_string()
      let #(sql, with, expecting) =
        sql.create_spending(
          id:,
          amount_in_cent:,
          name: option.Some(name),
          manage_key:,
        )
      let with = list.map(with, parrot_to_sqlight)
      let create_spending =
        sqlight.query(
          sql,
          on: spending_store.connection,
          with:,
          expecting: expecting,
        )
        |> result.map_error(SqlError)
        |> result.try(fn(res) {
          list.first(res) |> result.replace_error(GenericError)
        })
        |> result.map(create_spending_to_spending)
      actor.send(reply_to, create_spending)
      actor.continue(spending_store)
    }
    GetSpendings(reply_to:) -> {
      let #(sql, with, expecting) = sql.get_spendings()
      let with = list.map(with, parrot_to_sqlight)
      let spendings =
        sqlight.query(
          sql,
          on: spending_store.connection,
          with:,
          expecting: expecting,
        )

      actor.send(
        reply_to,
        spendings
          |> result.map(list.map(_, get_spendings_to_spending))
          |> result.map_error(SqlError),
      )
      actor.continue(spending_store)
    }
    NewPledge(reply_to:, id:, amount_in_cent:, participant_name:) -> {
      let spending_id = uuid.v4_string()
      let #(sql, with) =
        sql.new_pledge(
          id: spending_id,
          spending_id: id,
          amount_in_cent:,
          participant_name: option.Some(participant_name),
        )

      let with = list.map(with, parrot_to_sqlight)
      let res =
        sqlight.query(
          sql,
          on: spending_store.connection,
          with:,
          expecting: decode.dynamic,
        )
      actor.send(
        reply_to,
        res
          |> result.replace(Nil)
          |> result.map_error(SqlError),
      )
      actor.continue(spending_store)
    }
  }
}

fn get_spending_to_spending(get_spending: sql.GetSpending) -> Spending {
  Spending(
    get_spending.id,
    get_spending.amount_in_cent,
    get_spending.name |> option.unwrap(""),
    [],
    get_spending.manage_key,
  )
}

fn get_spendings_to_spending(get_spending: sql.GetSpendings) -> Spending {
  Spending(
    get_spending.id,
    get_spending.amount_in_cent,
    get_spending.name |> option.unwrap(""),
    [],
    get_spending.manage_key,
  )
}

fn create_spending_to_spending(get_spending: sql.CreateSpending) -> Spending {
  Spending(
    get_spending.id,
    get_spending.amount_in_cent,
    get_spending.name |> option.unwrap(""),
    [],
    get_spending.manage_key,
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
