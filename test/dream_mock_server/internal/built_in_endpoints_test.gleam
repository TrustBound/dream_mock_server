import dream_mock_server/internal/built_in_endpoints
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import gleam/list

/// The request line of each built-in endpoint, in the order of the table.
fn built_in_request_lines() -> List(String) {
  [
    "GET /", "GET /get", "POST /post", "POST /content-type", "PUT /put",
    "PATCH /patch", "DELETE /delete", "GET /json", "GET /text", "GET /uuid",
    "GET /status/:code", "GET /large", "GET /empty", "GET /slow", "GET /gzip",
    "GET /deflate", "GET /identity", "GET /unknown-encoding",
    "GET /corrupted-gzip", "GET /echo-accept-encoding", "GET /non-utf8-error",
    "GET /redirect/301", "GET /redirect/302", "GET /redirect/303",
    "GET /redirect/307", "GET /redirect/308", "GET /redirect/chain",
    "GET /redirect/chain/2", "GET /redirect/absolute", "GET /stream/fast",
    "GET /stream/slow", "GET /stream/burst", "GET /stream/error",
    "GET /stream/huge", "GET /stream/drop", "GET /stream/json",
    "GET /stream/binary", "GET /stream/gzip", "GET /stream/deflate",
    "GET /stream/unknown-encoding",
  ]
}

pub fn tests() -> TestSuite {
  describe("dream_mock_server/internal/built_in_endpoints", [
    group("table", [
      it("has the 40 built-in endpoints in route order", fn() {
        // Act
        let request_lines =
          list.map(built_in_endpoints.table(), built_in_endpoints.request_line)

        // Assert
        request_lines
        |> should
        |> be_equal(built_in_request_lines())
        |> or_fail_with("Expected the 40 built-in endpoints")
      }),
    ]),
  ])
}
