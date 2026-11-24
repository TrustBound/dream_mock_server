//// The request and response types of the mock server core.
////
//// The endpoints take a `Request` and return a `Response`. These types are
//// plain data, so a test can call an endpoint without a socket. The module
//// `dream_mock_server/internal/mist_adapter` converts between these types and
//// the types of `dream_http_server`.

import gleam/http.{type Method}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/yielder.{type Yielder}

/// The parts of a request that the server knows before it reads the body.
///
/// `dream_mock_server/internal/routes.answer` uses them to find the endpoint.
/// The server reads the body only when an endpoint matches.
pub type RequestHead {
  /// The method, path, query and headers of a request.
  RequestHead(
    method: Method,
    path: String,
    query: Option(String),
    headers: List(#(String, String)),
  )
}

/// A request with its body, as an endpoint gets it.
pub type Request {
  /// The method, path, query, headers and body of a request.
  ///
  /// `query` is the raw query string without the `?`, or `None`. Header
  /// names from the server are in lowercase.
  Request(
    method: Method,
    path: String,
    query: Option(String),
    headers: List(#(String, String)),
    body: BitArray,
  )
}

/// The body of a response.
pub type Body {
  /// The whole body, sent with a `content-length` header.
  Bytes(BitArray)
  /// A body that the server sends in chunks, one chunk for each element.
  /// The server reads the next element only after it sent the previous one,
  /// so a `Yielder` that sleeps controls the timing of the chunks.
  Stream(Yielder(BitArray))
}

/// A response: the status, the headers and the body.
pub type Response {
  /// The status code, the headers in the order to send them, and the body.
  /// Header names are in lowercase.
  Response(status: Int, headers: List(#(String, String)), body: Body)
}

/// Adds the body to a request head.
///
/// ## Parameters
///
/// - `head`: The method, path, query and headers.
/// - `body`: The body bytes.
///
/// ## Returns
///
/// A `Request` with the fields of `head` and `body`.
pub fn with_body(head: RequestHead, body: BitArray) -> Request {
  Request(
    method: head.method,
    path: head.path,
    query: head.query,
    headers: head.headers,
    body: body,
  )
}

/// Finds the value of a request header. The name match ignores case.
///
/// ## Parameters
///
/// - `request`: The request.
/// - `name`: The header name, for example `"accept-encoding"`.
///
/// ## Returns
///
/// `Ok` with the value of the first header with that name, or `Error(Nil)`
/// when the request has no such header.
pub fn find_header(request: Request, name: String) -> Result(String, Nil) {
  let lowercase_name = string.lowercase(name)
  request.headers
  |> list.find(fn(header) { string.lowercase(header.0) == lowercase_name })
  |> result.map(fn(header) { header.1 })
}

/// Creates a text response with `content-type: text/plain; charset=utf-8`.
///
/// ## Parameters
///
/// - `status`: The status code.
/// - `body`: The body text.
///
/// ## Returns
///
/// A `Response` with the UTF-8 bytes of `body`.
pub fn text_response(status: Int, body: String) -> Response {
  Response(
    status: status,
    headers: [#("content-type", "text/plain; charset=utf-8")],
    body: Bytes(<<body:utf8>>),
  )
}

/// Creates a JSON response with
/// `content-type: application/json; charset=utf-8`.
///
/// ## Parameters
///
/// - `status`: The status code.
/// - `body`: The JSON text.
///
/// ## Returns
///
/// A `Response` with the UTF-8 bytes of `body`.
pub fn json_response(status: Int, body: String) -> Response {
  Response(
    status: status,
    headers: [#("content-type", "application/json; charset=utf-8")],
    body: Bytes(<<body:utf8>>),
  )
}

/// Creates a streamed response with one `content-type` header.
///
/// ## Parameters
///
/// - `status`: The status code.
/// - `stream`: The chunks, in order.
/// - `content_type`: The value of the `content-type` header.
///
/// ## Returns
///
/// A `Response` with a `Stream` body.
pub fn stream_response(
  status: Int,
  stream: Yielder(BitArray),
  content_type: String,
) -> Response {
  Response(
    status: status,
    headers: [#("content-type", content_type)],
    body: Stream(stream),
  )
}
