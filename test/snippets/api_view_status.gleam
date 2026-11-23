//// Doc comment: api_view.status_to_json

import dream_mock_server/views/api_view

/// The body of `GET /status/404`: `{"status":404}`.
pub fn status_body() -> String {
  api_view.status_to_json(404)
}
