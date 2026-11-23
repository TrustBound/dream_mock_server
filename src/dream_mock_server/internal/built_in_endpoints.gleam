//// The table of the built-in endpoints.
////
//// This table is the one source of the built-in endpoints.
//// `dream_mock_server/internal/routes` answers a request with the first
//// entry that matches its method and path, and `GET /` shows the page that
//// `dream_mock_server/views/index_view.format_index` makes from the same
//// entries, in the same order. An endpoint that is not in the table does
//// not exist, and an endpoint in the table is on the page.

import dream_mock_server/internal/api_endpoints
import dream_mock_server/internal/message.{type Request, type Response}
import dream_mock_server/internal/stream_endpoints
import gleam/http.{type Method}
import gleam/list
import gleam/string

/// One segment of the path pattern of an endpoint.
pub type Segment {
  /// A segment that must be this text. A request segment with one file
  /// extension also matches it.
  Literal(String)
  /// A segment that matches any text. The page shows it as `:name`.
  Parameter(name: String)
}

/// The heading that an endpoint has on the page of `GET /`.
pub type Group {
  InfoPage
  NonStreaming
  Compression
  Redirect
  Streaming
}

/// What answers the requests of an endpoint.
pub type Handler {
  /// The page of `GET /`. `dream_mock_server/internal/routes` makes this
  /// answer, because the page is made from this table.
  ListEndpoints
  /// A function that answers the request.
  Answer(fn(Request) -> Response)
}

/// One built-in endpoint.
pub type BuiltInEndpoint {
  BuiltInEndpoint(
    group: Group,
    method: Method,
    pattern: List(Segment),
    description: String,
    handler: Handler,
  )
}

/// Gives the heading of a group on the page of `GET /`.
///
/// ## Parameters
///
/// - `group`: The group.
///
/// ## Returns
///
/// The heading, without the colon.
pub fn group_title(group: Group) -> String {
  case group {
    InfoPage -> "Info Page"
    NonStreaming -> "Non-Streaming Endpoints"
    Compression -> "Compression Endpoints"
    Redirect -> "Redirect Endpoints"
    Streaming -> "Streaming Endpoints"
  }
}

/// Gives the path pattern of an endpoint as text.
///
/// ## Parameters
///
/// - `pattern`: The segments of the pattern.
///
/// ## Returns
///
/// The path, such as `/status/:code`. No segments give `/`.
pub fn path_pattern(pattern: List(Segment)) -> String {
  "/" <> string.join(list.map(pattern, segment_text), "/")
}

fn segment_text(segment: Segment) -> String {
  case segment {
    Literal(name) -> name
    Parameter(name) -> ":" <> name
  }
}

/// Gives the request line of an endpoint, such as `GET /status/:code`.
///
/// ## Parameters
///
/// - `endpoint`: The endpoint.
///
/// ## Returns
///
/// The method and the path pattern, with one space between them.
pub fn request_line(endpoint: BuiltInEndpoint) -> String {
  http.method_to_string(endpoint.method)
  <> " "
  <> path_pattern(endpoint.pattern)
}

/// The built-in endpoints, in the order of the route match and of the page.
///
/// ## Returns
///
/// Every built-in endpoint.
pub fn table() -> List(BuiltInEndpoint) {
  [
    BuiltInEndpoint(
      InfoPage,
      http.Get,
      [],
      "Text page that lists every built-in endpoint",
      ListEndpoints,
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Get,
      [Literal("get")],
      "Path and query as JSON",
      Answer(api_endpoints.get),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Post,
      [Literal("post")],
      "Request body as JSON, with status 201",
      Answer(api_endpoints.post),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Post,
      [Literal("content-type")],
      "The Content-Type of the request as text",
      Answer(api_endpoints.content_type),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Put,
      [Literal("put")],
      "Request body as JSON",
      Answer(api_endpoints.put),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Patch,
      [Literal("patch")],
      "Request body as JSON",
      Answer(api_endpoints.patch),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Delete,
      [Literal("delete")],
      "Path as JSON",
      Answer(api_endpoints.delete),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Get,
      [Literal("json")],
      "A fixed JSON object",
      Answer(api_endpoints.json_endpoint),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Get,
      [Literal("text")],
      "Hello, World! as text",
      Answer(api_endpoints.text),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Get,
      [Literal("uuid")],
      "A fixed UUID as JSON",
      Answer(api_endpoints.uuid),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Get,
      [Literal("status"), Parameter("code")],
      "Status code, with the code as JSON",
      Answer(api_endpoints.status),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Get,
      [Literal("large")],
      "A text body of 1,140,000 bytes",
      Answer(api_endpoints.large),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Get,
      [Literal("empty")],
      "An empty text body",
      Answer(api_endpoints.empty),
    ),
    BuiltInEndpoint(
      NonStreaming,
      http.Get,
      [Literal("slow")],
      "A short text after 5 seconds",
      Answer(api_endpoints.slow),
    ),
    BuiltInEndpoint(
      Compression,
      http.Get,
      [Literal("gzip")],
      "Hello, World! compressed with gzip",
      Answer(api_endpoints.gzip),
    ),
    BuiltInEndpoint(
      Compression,
      http.Get,
      [Literal("deflate")],
      "Hello, World! compressed with deflate",
      Answer(api_endpoints.deflate),
    ),
    BuiltInEndpoint(
      Compression,
      http.Get,
      [Literal("identity")],
      "Hello, World! with Content-Encoding: identity",
      Answer(api_endpoints.identity),
    ),
    BuiltInEndpoint(
      Compression,
      http.Get,
      [Literal("unknown-encoding")],
      "Text with Content-Encoding: br, not compressed",
      Answer(api_endpoints.unknown_encoding),
    ),
    BuiltInEndpoint(
      Compression,
      http.Get,
      [Literal("corrupted-gzip")],
      "Content-Encoding: gzip with bytes that are not gzip",
      Answer(api_endpoints.corrupted_gzip),
    ),
    BuiltInEndpoint(
      Compression,
      http.Get,
      [Literal("echo-accept-encoding")],
      "The Accept-Encoding of the request as text",
      Answer(api_endpoints.echo_accept_encoding),
    ),
    BuiltInEndpoint(
      Compression,
      http.Get,
      [Literal("non-utf8-error")],
      "Status 400 with a body that is not UTF-8",
      Answer(api_endpoints.non_utf8_error),
    ),
    BuiltInEndpoint(
      Redirect,
      http.Get,
      [Literal("redirect"), Literal("301")],
      "Status 301 to /text",
      Answer(api_endpoints.redirect_301),
    ),
    BuiltInEndpoint(
      Redirect,
      http.Get,
      [Literal("redirect"), Literal("302")],
      "Status 302 to /text",
      Answer(api_endpoints.redirect_302),
    ),
    BuiltInEndpoint(
      Redirect,
      http.Get,
      [Literal("redirect"), Literal("303")],
      "Status 303 to /text",
      Answer(api_endpoints.redirect_303),
    ),
    BuiltInEndpoint(
      Redirect,
      http.Get,
      [Literal("redirect"), Literal("307")],
      "Status 307 to /text",
      Answer(api_endpoints.redirect_307),
    ),
    BuiltInEndpoint(
      Redirect,
      http.Get,
      [Literal("redirect"), Literal("308")],
      "Status 308 to /text",
      Answer(api_endpoints.redirect_308),
    ),
    BuiltInEndpoint(
      Redirect,
      http.Get,
      [Literal("redirect"), Literal("chain")],
      "Status 302 to /redirect/chain/2",
      Answer(api_endpoints.redirect_chain),
    ),
    BuiltInEndpoint(
      Redirect,
      http.Get,
      [Literal("redirect"), Literal("chain"), Literal("2")],
      "Status 302 to /text",
      Answer(api_endpoints.redirect_chain_2),
    ),
    BuiltInEndpoint(
      Redirect,
      http.Get,
      [Literal("redirect"), Literal("absolute")],
      "Status 302 to /text as a full URL",
      Answer(api_endpoints.redirect_absolute),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("fast")],
      "10 chunks, one each 100 ms",
      Answer(stream_endpoints.stream_fast),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("slow")],
      "5 chunks, one each 2 s",
      Answer(stream_endpoints.stream_slow),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("burst")],
      "7 chunks with fixed, different delays (100-500 ms)",
      Answer(stream_endpoints.stream_burst),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("error")],
      "Status 500 first, then 3 chunks, one each 100 ms",
      Answer(stream_endpoints.stream_error),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("huge")],
      "100 chunks, one each 10 ms",
      Answer(stream_endpoints.stream_huge),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("drop")],
      "2 chunks, then the server closes the connection",
      Answer(stream_endpoints.stream_drop),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("json")],
      "5 JSON objects, one on each line, one each 200 ms",
      Answer(stream_endpoints.stream_json),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("binary")],
      "256 chunks of binary data, one each 10 ms",
      Answer(stream_endpoints.stream_binary),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("gzip")],
      "One gzip stream in 6 chunks",
      Answer(stream_endpoints.stream_gzip),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("deflate")],
      "One deflate stream in 6 chunks",
      Answer(stream_endpoints.stream_deflate),
    ),
    BuiltInEndpoint(
      Streaming,
      http.Get,
      [Literal("stream"), Literal("unknown-encoding")],
      "5 chunks with Content-Encoding: br, not compressed",
      Answer(stream_endpoints.stream_unknown_encoding),
    ),
  ]
}
