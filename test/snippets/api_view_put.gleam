//// Doc comment: api_view.put_to_json

import dream_mock_server/views/api_view

/// The body of `PUT /put` with the body `hello`:
/// `{"method":"PUT","url":"/put","data":"hello"}`.
pub fn put_body() -> String {
  api_view.put_to_json("/put", "hello")
}
