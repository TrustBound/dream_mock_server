//// Expected responses for the controller tests.

import dream/http/header.{Header}
import dream/http/response.{type Response, Response, Text}
import gleam/option.{None}

/// Creates the redirect response that the redirect endpoints return: the
/// status, a `Location` header and an empty body.
pub fn create_redirect_response(status: Int, location: String) -> Response {
  Response(
    status: status,
    body: Text(""),
    headers: [Header("Location", location)],
    cookies: [],
    content_type: None,
  )
}
