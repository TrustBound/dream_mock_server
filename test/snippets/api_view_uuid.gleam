//// Doc comment: api_view.uuid_to_json

import dream_mock_server/views/api_view

/// The body of `GET /uuid`:
/// `{"uuid":"123e4567-e89b-12d3-a456-426614174000"}`.
pub fn uuid_body() -> String {
  api_view.uuid_to_json()
}
