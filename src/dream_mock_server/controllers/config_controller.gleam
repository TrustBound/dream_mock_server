//// The controller of config mode.
////
//// When the server runs with `server.start_with_config`, every request comes
//// to `handle`. It returns the status and body of the first `MockRoute` that
//// matches the request, or 404 when no route matches.

import dream/http/request.{type Request}
import dream/http/response.{type Response, text_response}
import dream/router.{type EmptyServices}
import dream_mock_server/config.{
  type MockConfigContext, type MockRoute, type PathMatch, Exact, Prefix,
}
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
/// - `context`: Holds the routes of the config, in order.
/// - `_services`: Not used.
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
pub fn handle(
  request: Request,
  context: MockConfigContext,
  _services: EmptyServices,
) -> Response {
  case find_match(request, context.routes) {
    option.Some(route) -> text_response(route.status, route.body)
    option.None -> text_response(404, "Not found")
  }
}

fn find_match(
  request: Request,
  routes: List(MockRoute),
) -> option.Option(MockRoute) {
  case routes {
    [] -> option.None
    [route, ..rest] -> {
      case route_matches(request, route) {
        True -> option.Some(route)
        False -> find_match(request, rest)
      }
    }
  }
}

fn route_matches(request: Request, route: MockRoute) -> Bool {
  let path_ok = path_matches(request.path, route.path, route.path_match)
  let method_ok = case route.method {
    option.None -> True
    option.Some(m) -> request.method == m
  }
  path_ok && method_ok
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
