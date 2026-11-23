//// Splits request paths into segments for the route match.

import gleam/list
import gleam/string

/// Splits a path into its segments, without empty segments.
///
/// ## Parameters
///
/// - `path`: A request path, for example `"/status/404"`.
///
/// ## Returns
///
/// The segments in order. `"/status//404/"` gives `["status", "404"]`, and
/// `"/"` gives `[]`.
pub fn segments(path: String) -> List(String) {
  path
  |> string.split("/")
  |> list.filter(fn(segment) { segment != "" })
}

/// Removes a file extension from a path segment.
///
/// ## Parameters
///
/// - `segment`: One path segment.
///
/// ## Returns
///
/// The part before the dot when the segment has exactly one dot:
/// `"text.json"` gives `"text"`. Any other segment comes back unchanged:
/// `"text"` gives `"text"`, and `"a.b.c"` gives `"a.b.c"`.
pub fn strip_extension(segment: String) -> String {
  case string.split(segment, ".") {
    [base, _extension] -> base
    _no_single_extension -> segment
  }
}
