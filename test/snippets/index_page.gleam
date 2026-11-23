//// Doc comment: index_view.format_index

import dream_mock_server/views/index_view

/// The info page of `GET /`. The first line is
/// `Mock Server - Testing & Demo Endpoints`.
pub fn index_page() -> String {
  index_view.format_index()
}
