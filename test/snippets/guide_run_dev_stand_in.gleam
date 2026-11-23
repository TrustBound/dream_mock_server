//// Guide: Run the server while you develop
////
//// A program that runs the chat API stand-in on a fixed port until you
//// stop it.

import dream_mock_server/server
import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import gleam/string
import snippets/guide_stand_in_routes

/// Starts the chat API stand-in on http://localhost:4010. Returns when the
/// stand-in answers requests.
pub fn start() -> Result(server.ServerHandle, actor.StartError) {
  server.start_with_config(4010, guide_stand_in_routes.chat_routes())
}

/// Runs the chat API stand-in until you stop it.
pub fn main() -> Nil {
  case start() {
    Ok(_handle) -> {
      io.println("Chat API stand-in on http://localhost:4010")
      process.sleep_forever()
    }
    Error(start_error) ->
      io.println_error(
        "Cannot start the stand-in: " <> string.inspect(start_error),
      )
  }
}
