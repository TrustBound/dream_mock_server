//// Doc comment: api_view.post_to_json

import dream_mock_server/views/api_view

/// The body of `POST /post` with the body `hello`:
/// `{"method":"POST","url":"/post","data":"hello"}`.
pub fn post_body() -> String {
  api_view.post_to_json("/post", "hello")
}
