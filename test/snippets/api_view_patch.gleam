//// Doc comment: api_view.patch_to_json

import dream_mock_server/views/api_view

/// The body of `PATCH /patch` with the body `hello`:
/// `{"method":"PATCH","url":"/patch","data":"hello"}`.
pub fn patch_body() -> String {
  api_view.patch_to_json("/patch", "hello")
}
