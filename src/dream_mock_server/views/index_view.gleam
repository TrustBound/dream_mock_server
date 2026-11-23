//// Formats the info page of `GET /`.

import dream_mock_server/internal/built_in_endpoints.{type BuiltInEndpoint}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// Formats the info page of `GET /`.
///
/// ## Returns
///
/// Plain text that lists every built-in endpoint under a heading for its
/// group, with its method, its path and what it returns. The page is made
/// from the same table that the server uses to answer requests, in the order
/// of that table. It names no port, because it is the same on every port.
///
/// ## Example
///
/// ### Format the info page <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/index_page.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/views/index_view
///
/// /// The info page of `GET /`. The first line is
/// /// `Mock Server - Testing & Demo Endpoints`.
/// pub fn index_page() -> String {
///   index_view.format_index()
/// }
/// ```
pub fn format_index() -> String {
  let #(_last_group, endpoint_lines) =
    list.fold(built_in_endpoints.table(), #(None, []), add_endpoint_lines)
  let page_lines = [
    "Mock Server - Testing & Demo Endpoints",
    "",
    "This server provides both streaming and non-streaming endpoints for testing HTTP clients.",
    "",
    ..list.reverse(endpoint_lines)
  ]
  string.join(page_lines, "\n")
}

/// Adds the lines of one endpoint, in reverse order, after the lines so far.
/// A heading comes first when the group of the endpoint is new.
fn add_endpoint_lines(
  state: #(Option(built_in_endpoints.Group), List(String)),
  endpoint: BuiltInEndpoint,
) -> #(Option(built_in_endpoints.Group), List(String)) {
  let #(last_group, lines) = state
  let lines_with_heading = case last_group == Some(endpoint.group) {
    True -> lines
    False -> [
      "",
      built_in_endpoints.group_title(endpoint.group) <> ":",
      ..lines
    ]
  }
  let endpoint_lines = [
    "",
    "    " <> endpoint.description,
    "  " <> built_in_endpoints.request_line(endpoint),
    ..lines_with_heading
  ]
  #(Some(endpoint.group), endpoint_lines)
}
