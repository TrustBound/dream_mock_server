//// Formats the bodies of the built-in endpoints that do not stream.
////
//// Each function returns a string. JSON functions return compact JSON with the
//// fields in a fixed order.

import gleam/json

/// Formats the body of `GET /get`.
///
/// ## Parameters
///
/// - `path`: The request path.
/// - `query`: The raw query string.
///
/// ## Returns
///
/// The JSON `{"method":"GET","url":<path>,"query":<query>,"headers":[]}`.
pub fn get_to_json(path: String, query: String) -> String {
  get_to_json_object(path, query)
  |> json.to_string()
}

/// Formats the body of `POST /post`.
///
/// ## Parameters
///
/// - `path`: The request path.
/// - `body`: The request body as text.
///
/// ## Returns
///
/// The JSON `{"method":"POST","url":<path>,"data":<body>}`.
pub fn post_to_json(path: String, body: String) -> String {
  post_to_json_object(path, body)
  |> json.to_string()
}

/// Formats the body of `PUT /put`.
///
/// ## Parameters
///
/// - `path`: The request path.
/// - `body`: The request body as text.
///
/// ## Returns
///
/// The JSON `{"method":"PUT","url":<path>,"data":<body>}`.
pub fn put_to_json(path: String, body: String) -> String {
  put_to_json_object(path, body)
  |> json.to_string()
}

/// Formats the body of `PATCH /patch`.
///
/// ## Parameters
///
/// - `path`: The request path.
/// - `body`: The request body as text.
///
/// ## Returns
///
/// The JSON `{"method":"PATCH","url":<path>,"data":<body>}`.
pub fn patch_to_json(path: String, body: String) -> String {
  patch_to_json_object(path, body)
  |> json.to_string()
}

/// Formats the body of `DELETE /delete`.
///
/// ## Parameters
///
/// - `path`: The request path.
///
/// ## Returns
///
/// The JSON `{"method":"DELETE","url":<path>}`.
pub fn delete_to_json(path: String) -> String {
  delete_to_json_object(path)
  |> json.to_string()
}

/// Formats the body of `GET /status/:code`.
///
/// ## Parameters
///
/// - `code`: The status code of the response.
///
/// ## Returns
///
/// The JSON `{"status":<code>}`.
pub fn status_to_json(code: Int) -> String {
  status_to_json_object(code)
  |> json.to_string()
}

/// Formats the body of `GET /json`.
///
/// ## Returns
///
/// The JSON `{"message":"Hello, World!","success":true}`.
pub fn simple_json_to_string() -> String {
  simple_json_object()
  |> json.to_string()
}

/// Formats the body of `GET /uuid`.
///
/// ## Returns
///
/// The JSON `{"uuid":"123e4567-e89b-12d3-a456-426614174000"}`. The UUID is
/// always the same.
pub fn uuid_to_json() -> String {
  uuid_json_object()
  |> json.to_string()
}

/// Formats the body of `GET /text`.
///
/// ## Returns
///
/// The text `Hello, World!`.
pub fn text_to_string() -> String {
  "Hello, World!"
}

/// Formats the body of an error response.
///
/// ## Parameters
///
/// - `message`: The error message.
///
/// ## Returns
///
/// The JSON `{"error":<message>}`.
pub fn error_to_json(message: String) -> String {
  error_to_json_object(message)
  |> json.to_string()
}

// Private helpers - all named functions

fn get_to_json_object(path: String, query: String) -> json.Json {
  json.object([
    #("method", json.string("GET")),
    #("url", json.string(path)),
    #("query", json.string(query)),
    #("headers", json.array(from: [], of: json.string)),
  ])
}

fn post_to_json_object(path: String, body: String) -> json.Json {
  json.object([
    #("method", json.string("POST")),
    #("url", json.string(path)),
    #("data", json.string(body)),
  ])
}

fn put_to_json_object(path: String, body: String) -> json.Json {
  json.object([
    #("method", json.string("PUT")),
    #("url", json.string(path)),
    #("data", json.string(body)),
  ])
}

fn patch_to_json_object(path: String, body: String) -> json.Json {
  json.object([
    #("method", json.string("PATCH")),
    #("url", json.string(path)),
    #("data", json.string(body)),
  ])
}

fn delete_to_json_object(path: String) -> json.Json {
  json.object([
    #("method", json.string("DELETE")),
    #("url", json.string(path)),
  ])
}

fn status_to_json_object(code: Int) -> json.Json {
  json.object([
    #("status", json.int(code)),
  ])
}

fn simple_json_object() -> json.Json {
  json.object([
    #("message", json.string("Hello, World!")),
    #("success", json.bool(True)),
  ])
}

fn uuid_json_object() -> json.Json {
  let uuid_str = "123e4567-e89b-12d3-a456-426614174000"
  json.object([
    #("uuid", json.string(uuid_str)),
  ])
}

fn error_to_json_object(message: String) -> json.Json {
  json.object([
    #("error", json.string(message)),
  ])
}
