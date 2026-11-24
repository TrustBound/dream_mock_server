//// Doc comment: api_view.get_to_json

import dream_mock_server/views/api_view

/// The body of `GET /get?page=2`:
/// `{"method":"GET","url":"/get","query":"page=2","headers":[]}`.
pub fn get_body() -> String {
  api_view.get_to_json("/get", "page=2")
}
