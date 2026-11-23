//// Doc comment: api_view.error_to_json

import dream_mock_server/views/api_view

/// The error body of `GET /status/abc`: `{"error":"code must be an integer"}`.
pub fn error_body() -> String {
  api_view.error_to_json("code must be an integer")
}
