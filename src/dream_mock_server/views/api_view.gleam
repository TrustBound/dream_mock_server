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
///
/// ## Example
///
/// ### Format the body of a GET request <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/api_view_get.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/api_view
///
/// /// The body of `GET /get?page=2`:
/// /// `{"method":"GET","url":"/get","query":"page=2","headers":[]}`.
/// pub fn get_body() -> String {
///   api_view.get_to_json("/get", "page=2")
/// }
/// ```
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
///
/// ## Example
///
/// ### Format the body of a POST request <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/api_view_post.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/api_view
///
/// /// The body of `POST /post` with the body `hello`:
/// /// `{"method":"POST","url":"/post","data":"hello"}`.
/// pub fn post_body() -> String {
///   api_view.post_to_json("/post", "hello")
/// }
/// ```
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
///
/// ## Example
///
/// ### Format the body of a PUT request <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/api_view_put.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/api_view
///
/// /// The body of `PUT /put` with the body `hello`:
/// /// `{"method":"PUT","url":"/put","data":"hello"}`.
/// pub fn put_body() -> String {
///   api_view.put_to_json("/put", "hello")
/// }
/// ```
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
///
/// ## Example
///
/// ### Format the body of a PATCH request <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/api_view_patch.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/api_view
///
/// /// The body of `PATCH /patch` with the body `hello`:
/// /// `{"method":"PATCH","url":"/patch","data":"hello"}`.
/// pub fn patch_body() -> String {
///   api_view.patch_to_json("/patch", "hello")
/// }
/// ```
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
///
/// ## Example
///
/// ### Format the body of a DELETE request <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/api_view_delete.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/api_view
///
/// /// The body of `DELETE /delete`: `{"method":"DELETE","url":"/delete"}`.
/// pub fn delete_body() -> String {
///   api_view.delete_to_json("/delete")
/// }
/// ```
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
///
/// ## Example
///
/// ### Format the body of a status response <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/api_view_status.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/api_view
///
/// /// The body of `GET /status/404`: `{"status":404}`.
/// pub fn status_body() -> String {
///   api_view.status_to_json(404)
/// }
/// ```
pub fn status_to_json(code: Int) -> String {
  status_to_json_object(code)
  |> json.to_string()
}

/// Formats the body of `GET /json`.
///
/// ## Returns
///
/// The JSON `{"message":"Hello, World!","success":true}`.
///
/// ## Example
///
/// ### Format the fixed JSON body <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/api_view_simple_json.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/api_view
///
/// /// The body of `GET /json`: `{"message":"Hello, World!","success":true}`.
/// pub fn json_body() -> String {
///   api_view.simple_json_to_string()
/// }
/// ```
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
///
/// ## Example
///
/// ### Format the fixed UUID body <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/api_view_uuid.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/api_view
///
/// /// The body of `GET /uuid`:
/// /// `{"uuid":"123e4567-e89b-12d3-a456-426614174000"}`.
/// pub fn uuid_body() -> String {
///   api_view.uuid_to_json()
/// }
/// ```
pub fn uuid_to_json() -> String {
  uuid_json_object()
  |> json.to_string()
}

/// Formats the body of `GET /text`.
///
/// ## Returns
///
/// The text `Hello, World!`.
///
/// ## Example
///
/// ### Format the fixed text body <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/api_view_text.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/api_view
///
/// /// The body of `GET /text`: `Hello, World!`.
/// pub fn text_body() -> String {
///   api_view.text_to_string()
/// }
/// ```
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
///
/// ## Example
///
/// ### Format an error body <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/api_view_error.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/api_view
///
/// /// The error body of `GET /status/abc`: `{"error":"code must be an integer"}`.
/// pub fn error_body() -> String {
///   api_view.error_to_json("code must be an integer")
/// }
/// ```
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
