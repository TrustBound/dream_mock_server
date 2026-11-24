//// Expected responses for the endpoint tests.

import dream_mock_server/internal/message.{type Response, Bytes, Response}

/// Creates the redirect response that the redirect endpoints return: the
/// status, a `location` header and an empty body.
pub fn create_redirect_response(status: Int, location: String) -> Response {
  Response(
    status: status,
    headers: [#("location", location)],
    body: Bytes(<<>>),
  )
}
