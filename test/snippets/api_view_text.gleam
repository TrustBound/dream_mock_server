//// Doc comment: api_view.text_to_string

import dream_mock_server/views/api_view

/// The body of `GET /text`: `Hello, World!`.
pub fn text_body() -> String {
  api_view.text_to_string()
}
