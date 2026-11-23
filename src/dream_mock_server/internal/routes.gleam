//// Decides which endpoint answers a request.
////
//// This module is the pure core of the mock server: it has no socket. The
//// mist adapter gives it the head of each request and a function that reads
//// the body, and sends back the `Response` that `answer` returns.
////
//// The match follows the rules of the router that the mock server used
//// before 2.0.0, so every request gets the same answer as before:
////
//// - A path matches by its segments. Empty segments do not count, so
////   `/text/` and `//text` match `/text`.
//// - A literal segment also matches when the request segment has one file
////   extension: `/text.json` matches `/text`.
//// - A request with the method CONNECT, TRACE or a method that is not
////   standard is handled as GET.
//// - A request that matches no route gets status 404 with the body
////   `Route not found`. The server does not read its body.
//// - When the server cannot read the body of a request that matches, for
////   example a body larger than 10 MB, the response is status 400 with an
////   empty body.
////
//// ## Built-in endpoints
////
//// The built-in endpoints are the entries of
//// `dream_mock_server/internal/built_in_endpoints.table`. The match checks
//// them in the order of that table. `GET /` answers with the page of
//// `dream_mock_server/views/index_view.format_index`, which lists the same
//// entries.
////
//// ## Config mode
////
//// In config mode every request with the method GET, POST, PUT, DELETE or
//// PATCH goes to `dream_mock_server/internal/config_endpoint.handle`, for
//// every path. Other methods get the 404 `Route not found` response.

import dream_mock_server/config.{type MockRoute}
import dream_mock_server/internal/built_in_endpoints.{
  type Handler, type Segment, Answer, ListEndpoints, Literal, Parameter,
}
import dream_mock_server/internal/config_endpoint
import dream_mock_server/internal/message.{
  type Request, type RequestHead, type Response, Bytes, RequestHead, Response,
  text_response,
}
import dream_mock_server/internal/path
import dream_mock_server/views/index_view
import gleam/http.{type Method}
import gleam/list
import gleam/result

/// The largest request body that the server reads: 10 MB.
pub const max_body_size = 10_000_000

/// Which endpoints a server has.
pub type Mode {
  /// The built-in endpoints of `built_in_endpoints.table`.
  BuiltInEndpoints
  /// Only the routes of config mode, checked in list order.
  ConfiguredRoutes(routes: List(MockRoute))
}

/// A function that answers a request.
pub type Endpoint =
  fn(Request) -> Response

/// Answers a request.
///
/// ## Parameters
///
/// - `mode`: The endpoints of the server.
/// - `head`: The method, path, query and headers of the request.
/// - `read_body`: Reads the request body. `answer` calls it only when an
///   endpoint matches the request.
///
/// ## Returns
///
/// The response of the endpoint that matches. When no endpoint matches,
/// `route_not_found_response()`. When `read_body` returns `Error(Nil)`,
/// `bad_request_response()`.
pub fn answer(
  mode: Mode,
  head: RequestHead,
  read_body: fn() -> Result(BitArray, Nil),
) -> Response {
  let routed_head = RequestHead(..head, method: routing_method(head.method))
  case find_endpoint(mode, routed_head.method, routed_head.path) {
    Ok(endpoint) -> answer_with_body(endpoint, routed_head, read_body())
    Error(Nil) -> route_not_found_response()
  }
}

fn answer_with_body(
  endpoint: Endpoint,
  head: RequestHead,
  body: Result(BitArray, Nil),
) -> Response {
  case body {
    Ok(bytes) -> endpoint(message.with_body(head, bytes))
    Error(Nil) -> bad_request_response()
  }
}

/// Gives the method that the route match uses for a request method.
///
/// ## Parameters
///
/// - `method`: The method of the request.
///
/// ## Returns
///
/// `Get` for `Connect`, `Trace` and `Other`. Any other method comes back
/// unchanged.
pub fn routing_method(method: Method) -> Method {
  case method {
    http.Connect | http.Trace | http.Other(_) -> http.Get
    standard_method -> standard_method
  }
}

/// Finds the endpoint for a method and a path.
///
/// ## Parameters
///
/// - `mode`: The endpoints of the server.
/// - `method`: The method, after `routing_method`.
/// - `request_path`: The request path.
///
/// ## Returns
///
/// `Ok` with the endpoint, or `Error(Nil)` when no endpoint matches.
pub fn find_endpoint(
  mode: Mode,
  method: Method,
  request_path: String,
) -> Result(Endpoint, Nil) {
  case mode {
    BuiltInEndpoints -> find_built_in_endpoint(method, request_path)
    ConfiguredRoutes(routes) -> find_config_endpoint(method, routes)
  }
}

fn find_built_in_endpoint(
  method: Method,
  request_path: String,
) -> Result(Endpoint, Nil) {
  let segments = path.segments(request_path)
  built_in_endpoints.table()
  |> list.find(fn(built_in_endpoint) {
    built_in_endpoint.method == method
    && pattern_matches(built_in_endpoint.pattern, segments)
  })
  |> result.map(fn(built_in_endpoint) {
    handler_endpoint(built_in_endpoint.handler)
  })
}

fn handler_endpoint(handler: Handler) -> Endpoint {
  case handler {
    ListEndpoints -> index
    Answer(endpoint) -> endpoint
  }
}

/// Handles `GET /`: returns a text page that lists every built-in endpoint.
///
/// ## Parameters
///
/// - `_request`: Not used.
///
/// ## Returns
///
/// Status 200 with a `text/plain; charset=utf-8` body: the page of
/// `index_view.format_index`.
///
/// ## See Also
///
/// - `dream_mock_server/views/index_view.format_index`
pub fn index(_request: Request) -> Response {
  text_response(200, index_view.format_index())
}

fn find_config_endpoint(
  method: Method,
  routes: List(MockRoute),
) -> Result(Endpoint, Nil) {
  case method {
    http.Get | http.Post | http.Put | http.Delete | http.Patch ->
      Ok(config_endpoint.handle(_, routes))
    _other_method -> Error(Nil)
  }
}

fn pattern_matches(pattern: List(Segment), segments: List(String)) -> Bool {
  case pattern, segments {
    [], [] -> True
    [Literal(name), ..pattern_rest], [segment, ..segments_rest] ->
      literal_matches(name, segment)
      && pattern_matches(pattern_rest, segments_rest)
    [Parameter(_name), ..pattern_rest], [_segment, ..segments_rest] ->
      pattern_matches(pattern_rest, segments_rest)
    _pattern, _segments -> False
  }
}

fn literal_matches(name: String, segment: String) -> Bool {
  segment == name || path.strip_extension(segment) == name
}

/// The response when no endpoint matches a request.
///
/// ## Returns
///
/// Status 404 with the `text/plain; charset=utf-8` body `Route not found`.
pub fn route_not_found_response() -> Response {
  text_response(404, "Route not found")
}

/// The response when the server cannot read the request body.
///
/// ## Returns
///
/// Status 400 with no headers and an empty body.
pub fn bad_request_response() -> Response {
  Response(status: 400, headers: [], body: Bytes(<<>>))
}
