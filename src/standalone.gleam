//// Runs the mock server as an application on port 3004.
////
//// For tests that start and stop the server from Gleam code, use
//// `dream_mock_server/server` instead.
////
//// ## Usage
////
//// Run the server from the root of the package:
////
//// ### Run the server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/scripts/run-server-smoke.sh#L55"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
////
//// ```sh
//// gleam run -m standalone
//// ```
////
//// The server listens on `http://localhost:3004/` until you stop it.
//// `GET /` lists the endpoints.

import dream_mock_server/internal/standalone_runner

/// Starts the mock server with the built-in endpoints on `localhost:3004`.
///
/// The function does not return while the server runs.
///
/// ## Errors
///
/// Panics when the server cannot listen on port 3004, for example when
/// another process uses the port.
///
/// ## Example
///
/// ### Run the server in a new process <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/standalone_main.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import gleam/erlang/process
/// import standalone
///
/// /// Runs the mock server on port 3004 in a new process. Kill the process to
/// /// stop the server.
/// pub fn start_in_background() -> process.Pid {
///   process.spawn_unlinked(standalone.main)
/// }
/// ```
pub fn main() -> Nil {
  standalone_runner.serve_forever(3004)
}
