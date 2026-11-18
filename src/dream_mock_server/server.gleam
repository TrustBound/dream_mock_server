//// Starts and stops the mock server from Gleam code.
////
//// Use it in integration tests that need full control of the server: start it
//// on a port, send requests, then stop it. `start` serves the built-in
//// endpoints. `start_with_config` serves only the routes that you give.
////
//// ## Run a test body against the mock server <a href="https://github.com/TrustBound/dream_mock_server/blob/1.1.1/test/snippets/programmatic_mode.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
////
//// ```gleam
//// import dream_mock_server/server
//// import gleam/int
//// import gleam/otp/actor
////
//// pub fn with_mock_server(
////   port: Int,
////   test_body: fn(String) -> outcome,
//// ) -> Result(outcome, actor.StartError) {
////   case server.start(port) {
////     Ok(handle) -> {
////       // Make HTTP requests to the base URL, http://localhost:<port>
////       let outcome = test_body("http://localhost:" <> int.to_string(port))
////       server.stop(handle)
////       Ok(outcome)
////     }
////     Error(start_error) -> Error(start_error)
////   }
//// }
//// ```
////
//// ## Built-in endpoints
////
//// `GET /` returns a text page that lists every endpoint. The main ones:
////
//// - `GET /get`, `POST /post`, `PUT /put`, `PATCH /patch`, `DELETE /delete`:
////   echo the request as JSON
//// - `GET /json`, `GET /text`, `GET /uuid`, `GET /empty`, `GET /large`: fixed
////   bodies
//// - `GET /status/:code`: a response with any status code
//// - `GET /slow`: a response after 5 seconds
//// - `GET /gzip`, `GET /deflate` and other compression endpoints
//// - `GET /redirect/301` and other redirect endpoints
//// - `GET /stream/fast`, `GET /stream/slow`, `GET /stream/burst`,
////   `GET /stream/error`, `GET /stream/drop`, `GET /stream/huge`,
////   `GET /stream/json`, `GET /stream/binary`: streams with fixed chunks and
////   timing
////
//// See `dream_mock_server/router.create_router` for the full list.

import dream/servers/mist/server.{bind, context, listen_with_handle, router} as dream_server
import dream_mock_server/config.{type MockRoute, MockConfigContext}
import dream_mock_server/router.{create_config_router, create_router}
import gleam/otp/actor

/// Starts the mock server with the built-in endpoints on a port.
///
/// The server listens on `localhost`. The function returns when the server
/// accepts connections, so you can send requests at once.
///
/// ## Parameters
///
/// - `port`: The TCP port to listen on. There is no default port.
///
/// ## Returns
///
/// `Ok` with a `ServerHandle`. Give it to `stop` to stop the server.
///
/// ## Errors
///
/// `Error(actor.InitFailed(message))` when the server cannot listen on the
/// port, for example when another process uses it. The message names the port.
///
/// ## Example
///
/// ### Start, use and stop the server <a href="https://github.com/TrustBound/dream_mock_server/blob/1.1.1/test/snippets/programmatic_control.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream/servers/mist/server as dream_server
/// import dream_mock_server/server
/// import gleam/int
/// import gleam/result
/// import gleam/string
/// import snippets/http_helper
///
/// pub fn fetch_text(port: Int) -> Result(#(Int, String), String) {
///   // Start server
///   use handle <- result.try(start_server(port))
///
///   // Use server
///   let response =
///     http_helper.get("http://localhost:" <> int.to_string(port) <> "/text")
///
///   // Stop server
///   server.stop(handle)
///   response
/// }
///
/// fn start_server(port: Int) -> Result(dream_server.ServerHandle, String) {
///   server.start(port)
///   |> result.map_error(string.inspect)
/// }
/// ```
///
/// ## See Also
///
/// - `start_with_config` to serve only your own routes
/// - `stop`
pub fn start(port: Int) -> Result(dream_server.ServerHandle, actor.StartError) {
  dream_server.new()
  |> router(create_router())
  |> bind("localhost")
  |> listen_with_handle(port)
}

/// Starts the mock server with your own routes on a port.
///
/// In this mode the server has no built-in endpoints: the routes in `config`
/// are the only ones. Use it when a test needs a fixed upstream, for example
/// a proxy test that needs a status and body for each path.
///
/// The routes are checked in list order, and the first route that matches
/// wins. A route matches when its path matches (`Exact` or `Prefix`) and its
/// method is `None` or the method of the request. When no route matches, the
/// response is status 404 with the body `Not found`.
///
/// ## Parameters
///
/// - `port`: The TCP port to listen on.
/// - `config`: The routes, in the order to check them.
///
/// ## Returns
///
/// `Ok` with a `ServerHandle`. Give it to `stop` to stop the server.
///
/// ## Errors
///
/// `Error(actor.InitFailed(message))` when the server cannot listen on the
/// port, for example when another process uses it.
///
/// ## Example
///
/// ### Start with one prefix route <a href="https://github.com/TrustBound/dream_mock_server/blob/1.1.1/test/snippets/config_mode_prefix.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream/servers/mist/server as dream_server
/// import dream_mock_server/config.{type MockRoute, MockRoute, Prefix}
/// import dream_mock_server/server
/// import gleam/option.{None}
/// import gleam/otp/actor
///
/// /// One route: path /v1/chat/completions (prefix match), any method, 200 + JSON body
/// pub fn chat_completion_routes() -> List(MockRoute) {
///   [
///     MockRoute(
///       path: "/v1/chat/completions",
///       path_match: Prefix,
///       method: None,
///       status: 200,
///       body: "{\"choices\":[{\"message\":{\"content\":\"\"}}]}",
///     ),
///   ]
/// }
///
/// pub fn start_chat_mock(
///   port: Int,
/// ) -> Result(dream_server.ServerHandle, actor.StartError) {
///   // Point your proxy or client at http://localhost:<port>,
///   // then call server.stop(handle).
///   server.start_with_config(port, chat_completion_routes())
/// }
/// ```
///
/// ## See Also
///
/// - `dream_mock_server/config.MockRoute`
/// - `start` for the built-in endpoints
pub fn start_with_config(
  port: Int,
  config: List(MockRoute),
) -> Result(dream_server.ServerHandle, actor.StartError) {
  dream_server.new()
  |> context(MockConfigContext(routes: config))
  |> router(create_config_router())
  |> bind("localhost")
  |> listen_with_handle(port)
}

/// Stops a server that `start` or `start_with_config` started.
///
/// The function returns when the server is down and its port is closed. It is
/// safe to call it again with the same handle: a second call does nothing.
///
/// ## Parameters
///
/// - `handle`: The handle that `start` or `start_with_config` returned.
///
/// ## Returns
///
/// `Nil`.
///
/// ## Example
///
/// ### Start, use and stop the server <a href="https://github.com/TrustBound/dream_mock_server/blob/1.1.1/test/snippets/programmatic_control.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream/servers/mist/server as dream_server
/// import dream_mock_server/server
/// import gleam/int
/// import gleam/result
/// import gleam/string
/// import snippets/http_helper
///
/// pub fn fetch_text(port: Int) -> Result(#(Int, String), String) {
///   // Start server
///   use handle <- result.try(start_server(port))
///
///   // Use server
///   let response =
///     http_helper.get("http://localhost:" <> int.to_string(port) <> "/text")
///
///   // Stop server
///   server.stop(handle)
///   response
/// }
///
/// fn start_server(port: Int) -> Result(dream_server.ServerHandle, String) {
///   server.start(port)
///   |> result.map_error(string.inspect)
/// }
/// ```
pub fn stop(handle: dream_server.ServerHandle) -> Nil {
  dream_server.stop(handle)
}
