//// Types for config mode.
////
//// Pass a list of `MockRoute` to `server.start_with_config` to choose the
//// status and body of each path. The mock server adds no built-in endpoints in
//// this mode: the routes you give are the only ones.

import gleam/http.{type Method}
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
/// - `method`: `Some(method)` to match only that method, for example
///   `Some(http.Post)` with `import gleam/http`, or `None` to match every
///   method. The match uses the method that the request sent, so
///   `Some(http.Trace)` matches a TRACE request and
///   `Some(http.Other("PURGE"))` matches a PURGE request. The name in
///   `Other` is case-sensitive. A request with the method HEAD or OPTIONS
///   matches no route.
/// - `status`: The HTTP status code of the response.
/// - `body`: The response body, sent as it is with the content type
///   `text/plain; charset=utf-8`.
///
/// ## Example
///
/// ### A specific route before a prefix route <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_ordering.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
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
