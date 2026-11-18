//// Requests for the controller and router tests.

import dream/http/request.{type Method, type Request, Http, Http1, Request, Text}
import gleam/option.{None}

/// Creates a request with an empty text body and no headers.
pub fn create_request(method: Method, path: String) -> Request {
  Request(
    method: method,
    protocol: Http,
    version: Http1,
    path: path,
    query: "",
    params: [],
    host: None,
    port: None,
    remote_address: None,
    body: Text(""),
    headers: [],
    cookies: [],
    content_type: None,
    content_length: None,
  )
}
