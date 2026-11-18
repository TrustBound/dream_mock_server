//// Controllers for the endpoints that do not stream.
////
//// `router.create_router` sends requests to these functions. Each one builds
//// a fixed, predictable response, so a test of an HTTP client can compare the
//// result exactly. The views in `dream_mock_server/views/api_view` format the
//// JSON bodies.
////
//// Every controller takes the Dream controller arguments: the request, an
//// `EmptyContext` and `EmptyServices`. Most of them do not read the request.

import dream/context.{type EmptyContext}
import dream/http/header.{Header}
import dream/http/request.{type Request, body_as_string, get_int_param}
import dream/http/response.{type Response, json_response, text_response}
import dream/http/status
import dream/router.{type EmptyServices}
import dream_mock_server/compression
import dream_mock_server/views/api_view
import gleam/erlang/process
import gleam/list
import gleam/option
import gleam/string

/// Handles `GET /get`: returns the path and the query string as JSON.
///
/// Use it to check that a client sends the right path and query parameters.
///
/// ## Parameters
///
/// - `request`: The request. Its `path` and raw `query` go into the JSON.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with an `application/json` body such as
/// `{"method":"GET","url":"/get","query":"page=1","headers":[]}`.
/// The `headers` field is always an empty list.
pub fn get(
  request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  json_response(status.ok, api_view.get_to_json(request.path, request.query))
}

/// Handles `POST /post`: echoes the request body as JSON.
///
/// Use it to check that a client sends the right request body.
///
/// ## Parameters
///
/// - `request`: The request. Its `path` and its body as UTF-8 text go into the JSON.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 201 with an `application/json` body such as
/// `{"method":"POST","url":"/post","data":"<request body>"}`.
///
/// ## Errors
///
/// When the body is not valid UTF-8 text, returns status 400 with the
/// body `{"error":"Request body is not UTF-8 text"}`.
pub fn post(
  request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  echo_text_body(request, status.created, api_view.post_to_json)
}

/// Handles `PUT /put`: echoes the request body as JSON.
///
/// Use it to check that a client sends the right request body.
///
/// ## Parameters
///
/// - `request`: The request. Its `path` and its body as UTF-8 text go into the JSON.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with an `application/json` body such as
/// `{"method":"PUT","url":"/put","data":"<request body>"}`.
///
/// ## Errors
///
/// When the body is not valid UTF-8 text, returns status 400 with the
/// body `{"error":"Request body is not UTF-8 text"}`.
pub fn put(
  request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  echo_text_body(request, status.ok, api_view.put_to_json)
}

/// Handles `PATCH /patch`: echoes the request body as JSON.
///
/// Use it to check that a client sends the right request body.
///
/// ## Parameters
///
/// - `request`: The request. Its `path` and its body as UTF-8 text go into the JSON.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with an `application/json` body such as
/// `{"method":"PATCH","url":"/patch","data":"<request body>"}`.
///
/// ## Errors
///
/// When the body is not valid UTF-8 text, returns status 400 with the
/// body `{"error":"Request body is not UTF-8 text"}`.
pub fn patch(
  request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  echo_text_body(request, status.ok, api_view.patch_to_json)
}

/// Echo a text request body as JSON, or reply 400 when the body is not text
fn echo_text_body(
  request: Request,
  status_code: Int,
  format_echo: fn(String, String) -> String,
) -> Response {
  case body_as_string(request) {
    Ok(body) -> json_response(status_code, format_echo(request.path, body))
    Error(Nil) ->
      json_response(
        status.bad_request,
        api_view.error_to_json("Request body is not UTF-8 text"),
      )
  }
}

/// Handles `DELETE /delete`: returns the method and the path as JSON.
///
/// ## Parameters
///
/// - `request`: The request. Its `path` goes into the JSON.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the `application/json` body
/// `{"method":"DELETE","url":"/delete"}`.
pub fn delete(
  request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  json_response(status.ok, api_view.delete_to_json(request.path))
}

/// Handles `GET /status/:code`: returns a response with the status code of the path.
///
/// Use it to check how a client handles any status code, for example
/// `GET /status/503`.
///
/// ## Parameters
///
/// - `request`: The request. Its `code` path parameter is the status to return.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// The status `code` with the `application/json` body `{"status":<code>}`.
///
/// ## Errors
///
/// When `code` is missing or is not an integer, returns status 400 with
/// an `application/json` body such as `{"error":"code must be an integer"}`.
pub fn status(
  request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  case get_int_param(request, "code") {
    Ok(code) -> json_response(code, api_view.status_to_json(code))
    Error(error_msg) ->
      json_response(status.bad_request, api_view.error_to_json(error_msg))
  }
}

/// Handles `GET /json`: returns a small, fixed JSON object.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the `application/json` body
/// `{"message":"Hello, World!","success":true}`.
pub fn json_endpoint(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  json_response(status.ok, api_view.simple_json_to_string())
}

/// Handles `GET /text`: returns a fixed plain-text greeting.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the `text/plain; charset=utf-8` body `Hello, World!`.
pub fn text(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  text_response(status.ok, api_view.text_to_string())
}

/// Handles `GET /uuid`: returns a fixed UUID as JSON.
///
/// The UUID is always the same, so tests can compare it exactly.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the `application/json` body
/// `{"uuid":"123e4567-e89b-12d3-a456-426614174000"}`.
pub fn uuid(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  json_response(status.ok, api_view.uuid_to_json())
}

/// Handles `GET /large`: returns a body of about 1.1 MB.
///
/// Use it to check how a client handles a large body that is not streamed.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with a `text/plain; charset=utf-8` body of 20,000 copies of the
/// line `This is a repeated line to create a large response body.`.
pub fn large(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  // Generate ~1MB of text data
  let chunk = "This is a repeated line to create a large response body.\n"
  let repeated = string.repeat(chunk, 20_000)
  text_response(status.ok, repeated)
}

/// Handles `GET /empty`: returns an empty body.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with an empty `text/plain; charset=utf-8` body.
pub fn empty(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  text_response(status.ok, "")
}

/// Handles `GET /slow`: waits 5 seconds, then returns a short text.
///
/// Use it to check the timeout of a client. The process that handles the
/// request sleeps for the full 5 seconds.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the `text/plain; charset=utf-8` body `Slow response`.
pub fn slow(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  // Wait 5 seconds before responding
  process.sleep(5000)
  text_response(status.ok, "Slow response")
}

/// Handles `POST /content-type`: returns the `Content-Type` of the request as text.
///
/// Use it to check the content type that a client sends.
///
/// ## Parameters
///
/// - `request`: The request. Its `content_type` is the body of the response.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with a `text/plain; charset=utf-8` body that holds the
/// `Content-Type` value, or an empty body when the request has none.
pub fn content_type(
  request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let content_type = option.unwrap(request.content_type, "")
  text_response(status.ok, content_type)
}

/// Handles `GET /gzip`: returns `Hello, World!` compressed with gzip.
///
/// Use it to check that a client decompresses a gzip body.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the headers `Content-Type: text/plain` and
/// `Content-Encoding: gzip`, and the gzip bytes of `Hello, World!` as the body.
pub fn gzip(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let body = compression.gzip_compress(<<"Hello, World!":utf8>>)
  response.Response(
    status: status.ok,
    body: response.Bytes(body),
    headers: [
      Header("Content-Type", "text/plain"),
      Header("Content-Encoding", "gzip"),
    ],
    cookies: [],
    content_type: option.Some("text/plain"),
  )
}

/// Handles `GET /deflate`: returns `Hello, World!` compressed with deflate.
///
/// Use it to check that a client decompresses a deflate (zlib) body.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the headers `Content-Type: text/plain` and
/// `Content-Encoding: deflate`, and the zlib bytes of `Hello, World!` as the body.
pub fn deflate(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let body = compression.deflate_compress(<<"Hello, World!":utf8>>)
  response.Response(
    status: status.ok,
    body: response.Bytes(body),
    headers: [
      Header("Content-Type", "text/plain"),
      Header("Content-Encoding", "deflate"),
    ],
    cookies: [],
    content_type: option.Some("text/plain"),
  )
}

/// Handles `GET /identity`: returns plain text with `Content-Encoding: identity`.
///
/// Use it to check that a client reads an `identity` body as it is.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the headers `Content-Type: text/plain; charset=utf-8` and
/// `Content-Encoding: identity`, and the body `Hello, World!`.
pub fn identity(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  response.Response(
    status: status.ok,
    body: response.Text("Hello, World!"),
    headers: [
      Header("Content-Type", "text/plain; charset=utf-8"),
      Header("Content-Encoding", "identity"),
    ],
    cookies: [],
    content_type: option.Some("text/plain; charset=utf-8"),
  )
}

/// Handles `GET /unknown-encoding`: returns plain text with `Content-Encoding: br`.
///
/// The body is not compressed. Use it to check what a client does with an
/// encoding that it does not support.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the headers `Content-Type: text/plain; charset=utf-8` and
/// `Content-Encoding: br`, and the body `raw-uncompressed-bytes`.
pub fn unknown_encoding(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  response.Response(
    status: status.ok,
    body: response.Text("raw-uncompressed-bytes"),
    headers: [
      Header("Content-Type", "text/plain; charset=utf-8"),
      Header("Content-Encoding", "br"),
    ],
    cookies: [],
    content_type: option.Some("text/plain; charset=utf-8"),
  )
}

/// Handles `GET /corrupted-gzip`: returns bytes that are not gzip, with `Content-Encoding: gzip`.
///
/// Use it to check that a client reports a body that it cannot decompress.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the headers `Content-Type: text/plain` and
/// `Content-Encoding: gzip`, and the body `this is not valid gzip data at all`.
pub fn corrupted_gzip(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  response.Response(
    status: status.ok,
    body: response.Bytes(<<"this is not valid gzip data at all":utf8>>),
    headers: [
      Header("Content-Type", "text/plain"),
      Header("Content-Encoding", "gzip"),
    ],
    cookies: [],
    content_type: option.Some("text/plain"),
  )
}

/// Handles `GET /non-utf8-error`: returns status 400 with a body that is not valid UTF-8.
///
/// The body is `Error: ` followed by the bytes 0xC0, 0xC1, 0xFE and 0xFF, which
/// are not valid in UTF-8. Use it to check that a client can read an error
/// response whose body is not text.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 400 with the header `Content-Type: text/plain` and the bytes above as
/// the body.
pub fn non_utf8_error(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  // "Error: " as ASCII + invalid UTF-8 bytes (0xC0, 0xC1, 0xFE, 0xFF)
  let body = <<69, 114, 114, 111, 114, 58, 32, 192, 193, 254, 255>>
  response.Response(
    status: status.bad_request,
    body: response.Bytes(body),
    headers: [Header("Content-Type", "text/plain")],
    cookies: [],
    content_type: option.Some("text/plain"),
  )
}

/// Handles `GET /echo-accept-encoding`: returns the `Accept-Encoding` header of the request as text.
///
/// The header name is matched in any letter case.
///
/// ## Parameters
///
/// - `request`: The request. Its `Accept-Encoding` header is the body of the response.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with a `text/plain; charset=utf-8` body that holds the header
/// value, or an empty body when the request has no `Accept-Encoding` header.
pub fn echo_accept_encoding(
  request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let accept_encoding =
    list.find(request.headers, fn(h) {
      string.lowercase(h.name) == "accept-encoding"
    })
  let value = case accept_encoding {
    Ok(found) -> found.value
    Error(Nil) -> ""
  }
  text_response(status.ok, value)
}

/// Handles `GET /redirect/301`: redirects to `/text` with status 301.
///
/// Use it to check how a client follows a 301 redirect.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 301 with the header `Location: /text` and an empty body.
///
/// ## See Also
///
/// - `redirect_chain` for a redirect in two steps
/// - `redirect_absolute` for a `Location` with the host
pub fn redirect_301(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  redirect_response(status.moved_permanently, "/text")
}

/// Handles `GET /redirect/302`: redirects to `/text` with status 302.
///
/// Use it to check how a client follows a 302 redirect.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 302 with the header `Location: /text` and an empty body.
///
/// ## See Also
///
/// - `redirect_chain` for a redirect in two steps
/// - `redirect_absolute` for a `Location` with the host
pub fn redirect_302(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  redirect_response(status.found, "/text")
}

/// Handles `GET /redirect/303`: redirects to `/text` with status 303.
///
/// Use it to check how a client follows a 303 redirect. A client changes the method to GET.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 303 with the header `Location: /text` and an empty body.
///
/// ## See Also
///
/// - `redirect_chain` for a redirect in two steps
/// - `redirect_absolute` for a `Location` with the host
pub fn redirect_303(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  redirect_response(status.see_other, "/text")
}

/// Handles `GET /redirect/307`: redirects to `/text` with status 307.
///
/// Use it to check how a client follows a 307 redirect. A client keeps the method and the body.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 307 with the header `Location: /text` and an empty body.
///
/// ## See Also
///
/// - `redirect_chain` for a redirect in two steps
/// - `redirect_absolute` for a `Location` with the host
pub fn redirect_307(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  redirect_response(status.temporary_redirect, "/text")
}

/// Handles `GET /redirect/308`: redirects to `/text` with status 308.
///
/// Use it to check how a client follows a 308 redirect. A client keeps the method and the body. The redirect is permanent.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 308 with the header `Location: /text` and an empty body.
///
/// ## See Also
///
/// - `redirect_chain` for a redirect in two steps
/// - `redirect_absolute` for a `Location` with the host
pub fn redirect_308(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  redirect_response(308, "/text")
}

/// Handles `GET /redirect/chain`: the first step of a chain of two redirects.
///
/// `/redirect/chain` redirects to `/redirect/chain/2`, which redirects to
/// `/text`. Use it to check that a client follows more than one redirect.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 302 with the header `Location: /redirect/chain/2` and an empty body.
///
/// ## See Also
///
/// - `redirect_chain_2` for the second step
pub fn redirect_chain(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  redirect_response(status.found, "/redirect/chain/2")
}

/// Handles `GET /redirect/chain/2`: the second step of a chain of two redirects.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 302 with the header `Location: /text` and an empty body.
///
/// ## See Also
///
/// - `redirect_chain` for the first step
pub fn redirect_chain_2(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  redirect_response(status.found, "/text")
}

/// Handles `GET /redirect/absolute`: redirects to `/text` with a full URL in `Location`.
///
/// The URL uses the `Host` header of the request, so the redirect goes back to
/// the same server. Use it to check that a client follows an absolute
/// `Location`.
///
/// ## Parameters
///
/// - `request`: The request. Its `Host` header gives the host and port of the URL.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 302 with the header `Location: http://<host>/text` and an empty body.
/// When the request has no `Host` header, the host is `localhost:9876`.
pub fn redirect_absolute(
  request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let port_str = case
    list.find(request.headers, fn(h) { string.lowercase(h.name) == "host" })
  {
    Ok(host_header) -> host_header.value
    Error(Nil) -> "localhost:9876"
  }
  redirect_response(status.found, "http://" <> port_str <> "/text")
}

fn redirect_response(status_code: Int, location: String) -> Response {
  response.Response(
    status: status_code,
    body: response.Text(""),
    headers: [Header("Location", location)],
    cookies: [],
    content_type: option.None,
  )
}
