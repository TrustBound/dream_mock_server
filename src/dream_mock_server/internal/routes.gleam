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
//// **Info page:**
//// - `GET /` - Text page that lists the endpoints
////
//// **Request echo and fixed bodies:**
//// - `GET /get` - Path and query as JSON
//// - `POST /post` - Request body as JSON (status 201)
//// - `PUT /put` - Request body as JSON
//// - `PATCH /patch` - Request body as JSON
//// - `DELETE /delete` - Path as JSON
//// - `POST /content-type` - The request `Content-Type` as text
//// - `GET /json` - A fixed JSON object
//// - `GET /text` - `Hello, World!` as text
//// - `GET /uuid` - A fixed UUID as JSON
//// - `GET /status/:code` - A response with status `code`
//// - `GET /large` - A body of about 1.1 MB
//// - `GET /empty` - An empty body
//// - `GET /slow` - A response after 5 seconds
////
//// **Compression:**
//// - `GET /gzip` - gzip body
//// - `GET /deflate` - deflate body
//// - `GET /identity` - `Content-Encoding: identity`
//// - `GET /unknown-encoding` - `Content-Encoding: br`, not compressed
//// - `GET /corrupted-gzip` - `Content-Encoding: gzip` with bytes that are not gzip
//// - `GET /echo-accept-encoding` - The request `Accept-Encoding` as text
//// - `GET /non-utf8-error` - Status 400 with a body that is not UTF-8
////
//// **Redirects:**
//// - `GET /redirect/301`, `/302`, `/303`, `/307`, `/308` - Redirect to `/text`
//// - `GET /redirect/chain` - `/redirect/chain/2`, then `/text`
//// - `GET /redirect/absolute` - Redirect with a full URL
////
//// **Streaming:**
//// - `GET /stream/fast` - 10 chunks, one each 100 ms
//// - `GET /stream/slow` - 5 chunks, one each 2 s
//// - `GET /stream/burst` - 7 chunks with fixed, different delays
//// - `GET /stream/error` - 3 chunks with status 500
//// - `GET /stream/drop` - 2 chunks, then the connection closes
//// - `GET /stream/huge` - 100 chunks, one each 10 ms
//// - `GET /stream/json` - 5 JSON objects, one on each line
//// - `GET /stream/binary` - 256 chunks of binary data
//// - `GET /stream/gzip` - One gzip stream in chunks
//// - `GET /stream/deflate` - One deflate stream in chunks
//// - `GET /stream/unknown-encoding` - Chunks with `Content-Encoding: br`
////
//// ## Config mode
////
//// In config mode every request with the method GET, POST, PUT, DELETE or
//// PATCH goes to `dream_mock_server/internal/config_endpoint.handle`, for
//// every path. Other methods get the 404 `Route not found` response.

import dream_mock_server/config.{type MockRoute}
import dream_mock_server/internal/api_endpoints
import dream_mock_server/internal/config_endpoint
import dream_mock_server/internal/message.{
  type Request, type RequestHead, type Response, Bytes, RequestHead, Response,
  text_response,
}
import dream_mock_server/internal/path
import dream_mock_server/internal/stream_endpoints
import gleam/http.{type Method}
import gleam/list
import gleam/result

/// The largest request body that the server reads: 10 MB.
pub const max_body_size = 10_000_000

/// Which endpoints a server has.
pub type Mode {
  /// The built-in endpoints that the module documentation lists.
  BuiltInEndpoints
  /// Only the routes of config mode, checked in list order.
  ConfiguredRoutes(routes: List(MockRoute))
}

/// A function that answers a request.
pub type Endpoint =
  fn(Request) -> Response

type Segment {
  Literal(String)
  Parameter
}

type Route {
  Route(method: Method, pattern: List(Segment), endpoint: Endpoint)
}

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
  built_in_routes()
  |> list.find(fn(route) {
    route.method == method && pattern_matches(route.pattern, segments)
  })
  |> result.map(fn(route) { route.endpoint })
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
    [Parameter, ..pattern_rest], [_segment, ..segments_rest] ->
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

fn built_in_routes() -> List(Route) {
  [
    // Info page
    Route(http.Get, [], stream_endpoints.index),
    // Non-streaming endpoints
    Route(http.Get, [Literal("get")], api_endpoints.get),
    Route(http.Post, [Literal("post")], api_endpoints.post),
    Route(http.Post, [Literal("content-type")], api_endpoints.content_type),
    Route(http.Put, [Literal("put")], api_endpoints.put),
    Route(http.Patch, [Literal("patch")], api_endpoints.patch),
    Route(http.Delete, [Literal("delete")], api_endpoints.delete),
    Route(http.Get, [Literal("json")], api_endpoints.json_endpoint),
    Route(http.Get, [Literal("text")], api_endpoints.text),
    Route(http.Get, [Literal("uuid")], api_endpoints.uuid),
    Route(http.Get, [Literal("status"), Parameter], api_endpoints.status),
    Route(http.Get, [Literal("large")], api_endpoints.large),
    Route(http.Get, [Literal("empty")], api_endpoints.empty),
    Route(http.Get, [Literal("slow")], api_endpoints.slow),
    // Compression endpoints
    Route(http.Get, [Literal("gzip")], api_endpoints.gzip),
    Route(http.Get, [Literal("deflate")], api_endpoints.deflate),
    Route(http.Get, [Literal("identity")], api_endpoints.identity),
    Route(
      http.Get,
      [Literal("unknown-encoding")],
      api_endpoints.unknown_encoding,
    ),
    Route(http.Get, [Literal("corrupted-gzip")], api_endpoints.corrupted_gzip),
    Route(
      http.Get,
      [Literal("echo-accept-encoding")],
      api_endpoints.echo_accept_encoding,
    ),
    Route(http.Get, [Literal("non-utf8-error")], api_endpoints.non_utf8_error),
    // Redirect endpoints
    Route(
      http.Get,
      [Literal("redirect"), Literal("301")],
      api_endpoints.redirect_301,
    ),
    Route(
      http.Get,
      [Literal("redirect"), Literal("302")],
      api_endpoints.redirect_302,
    ),
    Route(
      http.Get,
      [Literal("redirect"), Literal("303")],
      api_endpoints.redirect_303,
    ),
    Route(
      http.Get,
      [Literal("redirect"), Literal("307")],
      api_endpoints.redirect_307,
    ),
    Route(
      http.Get,
      [Literal("redirect"), Literal("308")],
      api_endpoints.redirect_308,
    ),
    Route(
      http.Get,
      [Literal("redirect"), Literal("chain")],
      api_endpoints.redirect_chain,
    ),
    Route(
      http.Get,
      [Literal("redirect"), Literal("chain"), Literal("2")],
      api_endpoints.redirect_chain_2,
    ),
    Route(
      http.Get,
      [Literal("redirect"), Literal("absolute")],
      api_endpoints.redirect_absolute,
    ),
    // Streaming endpoints
    Route(
      http.Get,
      [Literal("stream"), Literal("fast")],
      stream_endpoints.stream_fast,
    ),
    Route(
      http.Get,
      [Literal("stream"), Literal("slow")],
      stream_endpoints.stream_slow,
    ),
    Route(
      http.Get,
      [Literal("stream"), Literal("burst")],
      stream_endpoints.stream_burst,
    ),
    Route(
      http.Get,
      [Literal("stream"), Literal("error")],
      stream_endpoints.stream_error,
    ),
    Route(
      http.Get,
      [Literal("stream"), Literal("huge")],
      stream_endpoints.stream_huge,
    ),
    Route(
      http.Get,
      [Literal("stream"), Literal("drop")],
      stream_endpoints.stream_drop,
    ),
    Route(
      http.Get,
      [Literal("stream"), Literal("json")],
      stream_endpoints.stream_json,
    ),
    Route(
      http.Get,
      [Literal("stream"), Literal("binary")],
      stream_endpoints.stream_binary,
    ),
    // Compressed streaming endpoints
    Route(
      http.Get,
      [Literal("stream"), Literal("gzip")],
      stream_endpoints.stream_gzip,
    ),
    Route(
      http.Get,
      [Literal("stream"), Literal("deflate")],
      stream_endpoints.stream_deflate,
    ),
    Route(
      http.Get,
      [Literal("stream"), Literal("unknown-encoding")],
      stream_endpoints.stream_unknown_encoding,
    ),
  ]
}
