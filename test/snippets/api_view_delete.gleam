//// Doc comment: api_view.delete_to_json

import dream_mock_server/views/api_view

/// The body of `DELETE /delete`: `{"method":"DELETE","url":"/delete"}`.
pub fn delete_body() -> String {
  api_view.delete_to_json("/delete")
}
