//// Guide: Run the server while you develop
////
//// A program that runs the chat API stand-in on a fixed port until you
//// stop it.

import dream_mock_server/server
import gleam/erlang/process
import gleam/io
import gleam/string
import snippets/guide_stand_in_routes

/// Runs the chat API stand-in on http://localhost:4010 until you stop it.
pub fn main() -> Nil {
  case server.start_with_config(4010, guide_stand_in_routes.chat_routes()) {
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
