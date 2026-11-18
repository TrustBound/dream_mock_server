//// Runs the mock server as an application on port 3004.
////
//// For tests that start and stop the server from Gleam code, use
//// `dream_mock_server/server` instead.
////
//// ## Usage
////
//// Run the server from the root of the package:
////
//// ```sh
//// gleam run -m standalone
//// ```
////
//// The server listens on `http://localhost:3004/` until you stop it.
//// `GET /` lists the endpoints. `dream_mock_server/router.create_router`
//// describes each one.

import dream/servers/mist/server.{bind, listen, router} as dream
import dream_mock_server/router.{create_router}

/// Starts the mock server with the built-in endpoints on `localhost:3004`.
///
/// The function does not return while the server runs.
///
/// ## Errors
///
/// Panics when the server cannot listen on port 3004, for example when
/// another process uses the port.
pub fn main() {
  dream.new()
  |> router(create_router())
  |> bind("localhost")
  |> listen(3004)
}
