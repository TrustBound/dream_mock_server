//// Runs the mock server until the process stops, for `standalone.main`.

import dream_mock_server/server
import gleam/erlang/process
import gleam/int
import gleam/string

/// Starts the mock server with the built-in endpoints on a port, and waits
/// forever.
///
/// ## Parameters
///
/// - `port`: The TCP port to listen on.
///
/// ## Returns
///
/// The function does not return while the server runs. The server stops
/// when the process that called this function stops.
///
/// ## Errors
///
/// Panics when the server cannot start, for example when another process
/// uses the port. The message names the port and the start error. A program
/// that cannot start its server has nothing else to do, so it stops with an
/// error.
pub fn serve_forever(port: Int) -> Nil {
  case server.start(port) {
    Ok(_handle) -> process.sleep_forever()
    Error(start_error) ->
      panic as {
        "The mock server cannot start on port "
        <> int.to_string(port)
        <> ": "
        <> string.inspect(start_error)
      }
  }
}
