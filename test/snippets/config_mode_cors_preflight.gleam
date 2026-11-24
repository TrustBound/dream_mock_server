//// Guide: routes that answer a CORS preflight and the request after it

import dream_mock_server/config.{type MockRoute, Exact, MockRoute}
import gleam/http.{Get, Options}
import gleam/option.{Some}

// OPTIONS /api/items -> 204 with no body
// GET /api/items     -> 200 []
// HEAD /api/items    -> 404 Not found (no route for HEAD)
pub fn preflight_routes() -> List(MockRoute) {
  [
    MockRoute("/api/items", Exact, Some(Options), 204, ""),
    MockRoute("/api/items", Exact, Some(Get), 200, "[]"),
  ]
}
