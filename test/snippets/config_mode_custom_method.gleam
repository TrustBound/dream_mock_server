//// Guide: a route for a method that is not standard

import dream_mock_server/config.{type MockRoute, Exact, MockRoute}
import gleam/http.{Other}
import gleam/option.{Some}

// PURGE /cache -> 200 purged
// GET /cache   -> 404 Not found
// Purge /cache -> 404 Not found (a method name is case-sensitive)
pub fn cache_routes() -> List(MockRoute) {
  [MockRoute("/cache", Exact, Some(Other("PURGE")), 200, "purged")]
}
