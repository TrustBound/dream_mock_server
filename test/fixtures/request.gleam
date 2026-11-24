//// Requests for the endpoint and route tests.

import dream_mock_server/internal/message.{
  type Request, type RequestHead, Request, RequestHead,
}
import gleam/http.{type Method}
import gleam/option.{None}

/// Creates a request with no query, no headers and an empty body.
pub fn create_request(method: Method, path: String) -> Request {
  Request(method: method, path: path, query: None, headers: [], body: <<>>)
}

/// Gives the head of a request: every field but the body.
pub fn head_of(request: Request) -> RequestHead {
  RequestHead(
    method: request.method,
    path: request.path,
    query: request.query,
    headers: request.headers,
  )
}
