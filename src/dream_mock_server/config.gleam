//// Types for config mode.
////
//// Pass a list of `MockRoute` to `server.start_with_config` to choose the
//// status and body of each path. The mock server adds no built-in endpoints in
//// this mode: the routes you give are the only ones.

import dream/http/request.{type Method}
import gleam/option

/// How a route path matches the request path.
///
/// Use `Exact` for one path, and `Prefix` for a family of paths, for example
/// `/api` for `/api/v1/users`.
pub type PathMatch {
  /// The request path is the same as the route path.
  Exact
  /// The request path starts with the route path: `/api` matches `/api`,
  /// `/api/v1` and also `/apiary`. End the route path with `/` to match
  /// only the paths below it.
  Prefix
}

/// One route of config mode: which requests it matches, and the response.
///
/// `server.start_with_config` checks the routes in list order. The first
/// route that matches the request wins, so put specific routes before broad
/// `Prefix` routes.
///
/// ## Fields
///
/// - `path`: The path to match, for example `"/v1/chat/completions"`.
/// - `path_match`: `Exact` or `Prefix`.
/// - `method`: `Some(method)` to match only that method, or `None` to match
///   every method.
/// - `status`: The HTTP status code of the response.
/// - `body`: The response body, sent as it is with the content type
///   `text/plain; charset=utf-8`.
///
/// ## Example
///
/// ### A specific route before a prefix route <a href="https://github.com/TrustBound/dream_mock_server/blob/1.1.1/test/snippets/config_mode_ordering.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/config.{type MockRoute, Exact, MockRoute, Prefix}
/// import gleam/option.{None}
///
/// // Good: specific before broad prefix
/// pub fn api_routes() -> List(MockRoute) {
///   [
///     MockRoute("/api/special", Exact, None, 200, "special"),
///     MockRoute("/api", Prefix, None, 200, "general"),
///   ]
/// }
/// ```
///
/// ## See Also
///
/// - `dream_mock_server/server.start_with_config`
pub type MockRoute {
  /// A route with all five fields. See the type for each field.
  MockRoute(
    path: String,
    path_match: PathMatch,
    method: option.Option(Method),
    status: Int,
    body: String,
  )
}

/// The context of the config-mode router: the routes to match.
///
/// `server.start_with_config` creates it from your route list. You need it
/// only to run `router.create_config_router` with your own Dream server.
pub type MockConfigContext {
  /// Holds the routes, in the order that they are checked.
  MockConfigContext(routes: List(MockRoute))
}
