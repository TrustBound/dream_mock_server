//// Doc comment: api_view.simple_json_to_string

import dream_mock_server/views/api_view

/// The body of `GET /json`: `{"message":"Hello, World!","success":true}`.
pub fn json_body() -> String {
  api_view.simple_json_to_string()
}
