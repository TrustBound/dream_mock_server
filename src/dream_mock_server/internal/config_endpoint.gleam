//// The endpoint of config mode.
////
//// When the server runs with `server.start_with_config`, every request
//// comes to `handle`, with the method that the request sent, HEAD and
//// OPTIONS included. It returns the status and body of the first `MockRoute`
//// that matches the request, or 404 when no route matches. For a HEAD
//// request, `dream_http_server` sends the headers of this response and no
//// body.

import dream_mock_server/config.{type MockRoute, type PathMatch, Exact, Prefix}
import dream_mock_server/internal/message.{
  type Request, type Response, text_response,
}
import gleam/list
import gleam/option
import gleam/string

/// Handles a request in config mode.
///
/// A route matches when its path matches (`Exact`: the same path, `Prefix`:
/// the request path starts with the route path) and its method is `None` or
/// the method of the request. The routes are checked in list order, and the
/// first match wins.
///
/// ## Parameters
///
/// - `request`: The request. Its `path` and `method` select the route.
/// - `routes`: The routes of the config, in the order to check them.
///
/// ## Returns
///
/// The `status` and `body` of the first route that matches, as a
/// `text/plain; charset=utf-8` response. When no route matches, status 404
/// with the body `Not found`.
///
/// ## See Also
///
/// - `dream_mock_server/server.start_with_config`
/// - `dream_mock_server/config.MockRoute`
pub fn handle(request: Request, routes: List(MockRoute)) -> Response {
  case list.find(routes, route_matches(request, _)) {
    Ok(route) -> text_response(route.status, route.body)
    Error(Nil) -> text_response(404, "Not found")
  }
}

fn route_matches(request: Request, route: MockRoute) -> Bool {
  let path_matched = path_matches(request.path, route.path, route.path_match)
  let method_matched = case route.method {
    option.None -> True
    option.Some(method) -> request.method == method
  }
  path_matched && method_matched
}

fn path_matches(
  request_path: String,
  route_path: String,
  path_match: PathMatch,
) -> Bool {
  case path_match {
    Exact -> request_path == route_path
    Prefix -> string.starts_with(request_path, route_path)
  }
}
