import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/otp/actor.{type Next, type StartError, type Started}
import gleam/otp/supervision
import youid/uuid

pub type Session {
  Session(id: String, amount_in_cent: Int)
}

pub type SessionStore =
  dict.Dict(String, Session)

pub type Message {
  Get(reply_to: Subject(Result(Session, Nil)), id: String)
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
  actor.new(dict.new())
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
      actor.send(reply_to, dict.get(session_store, id))
      actor.continue(session_store)
    }
    New(reply_to, amount_in_cent) -> {
      let id = uuid.v4_string()
      let session_store =
        dict.insert(session_store, id, Session(id:, amount_in_cent:))
      actor.send(reply_to, id)
      actor.continue(session_store)
    }
  }
}
