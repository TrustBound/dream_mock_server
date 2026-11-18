//// The routers of the mock server.
////
//// `create_router` holds every built-in endpoint. `create_config_router` sends
//// every request to the config-mode controller. `server.start` and
//// `server.start_with_config` use them, and you can use them with a Dream
//// server that you set up yourself.
////
//// ## Built-in endpoints
////
//// **Info page:**
//// - `GET /` - Text page that lists the endpoints
////
//// **Request echo and fixed bodies:**
//// - `GET /get` - Path and query as JSON
//// - `POST /post` - Request body as JSON (status 201)
//// - `PUT /put` - Request body as JSON
//// - `PATCH /patch` - Request body as JSON
//// - `DELETE /delete` - Path as JSON
//// - `POST /content-type` - The request `Content-Type` as text
//// - `GET /json` - A fixed JSON object
//// - `GET /text` - `Hello, World!` as text
//// - `GET /uuid` - A fixed UUID as JSON
//// - `GET /status/:code` - A response with status `code`
//// - `GET /large` - A body of about 1.1 MB
//// - `GET /empty` - An empty body
//// - `GET /slow` - A response after 5 seconds
////
//// **Compression:**
//// - `GET /gzip` - gzip body
//// - `GET /deflate` - deflate body
//// - `GET /identity` - `Content-Encoding: identity`
//// - `GET /unknown-encoding` - `Content-Encoding: br`, not compressed
//// - `GET /corrupted-gzip` - `Content-Encoding: gzip` with bytes that are not gzip
//// - `GET /echo-accept-encoding` - The request `Accept-Encoding` as text
//// - `GET /non-utf8-error` - Status 400 with a body that is not UTF-8
////
//// **Redirects:**
//// - `GET /redirect/301`, `/302`, `/303`, `/307`, `/308` - Redirect to `/text`
//// - `GET /redirect/chain` - `/redirect/chain/2`, then `/text`
//// - `GET /redirect/absolute` - Redirect with a full URL
////
//// **Streaming:**
//// - `GET /stream/fast` - 10 chunks, one each 100 ms
//// - `GET /stream/slow` - 5 chunks, one each 2 s
//// - `GET /stream/burst` - 7 chunks with fixed, different delays
//// - `GET /stream/error` - 3 chunks with status 500
//// - `GET /stream/drop` - 2 chunks, then the connection closes
//// - `GET /stream/huge` - 100 chunks, one each 10 ms
//// - `GET /stream/json` - 5 JSON objects, one on each line
//// - `GET /stream/binary` - 256 chunks of binary data
//// - `GET /stream/gzip` - One gzip stream in chunks
//// - `GET /stream/deflate` - One deflate stream in chunks
//// - `GET /stream/unknown-encoding` - Chunks with `Content-Encoding: br`

import dream/context.{type EmptyContext}
import dream/http/request.{Delete, Get, Patch, Post, Put}
import dream/router.{type EmptyServices, type Router, route, router}
import dream_mock_server/config.{type MockConfigContext}
import dream_mock_server/controllers/api_controller
import dream_mock_server/controllers/config_controller
import dream_mock_server/controllers/stream_controller

/// Creates the router with every built-in endpoint.
///
/// `server.start` uses this router. Use it yourself when you need other Dream
/// server settings, for example another bind address.
///
/// ## Returns
///
/// A router for the built-in endpoints, with an `EmptyContext` and
/// `EmptyServices`. The module documentation lists the endpoints.
///
/// ## Example
///
/// ### Serve the endpoints from your own server <a href="https://github.com/TrustBound/dream_mock_server/blob/1.1.1/test/snippets/own_server.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream/servers/mist/server as dream_server
/// import dream_mock_server/router
/// import gleam/otp/actor
///
/// pub fn start_own_server(
///   port: Int,
/// ) -> Result(dream_server.ServerHandle, actor.StartError) {
///   dream_server.new()
///   |> dream_server.router(router.create_router())
///   |> dream_server.bind("localhost")
///   |> dream_server.listen_with_handle(port)
/// }
/// ```
///
/// ## See Also
///
/// - `dream_mock_server/server.start`
pub fn create_router() -> Router(EmptyContext, EmptyServices) {
  router()
  // Info page
  |> route(
    method: Get,
    path: "/",
    controller: stream_controller.index,
    middleware: [],
  )
  // Non-streaming endpoints
  |> route(
    method: Get,
    path: "/get",
    controller: api_controller.get,
    middleware: [],
  )
  |> route(
    method: Post,
    path: "/post",
    controller: api_controller.post,
    middleware: [],
  )
  |> route(
    method: Post,
    path: "/content-type",
    controller: api_controller.content_type,
    middleware: [],
  )
  |> route(
    method: Put,
    path: "/put",
    controller: api_controller.put,
    middleware: [],
  )
  |> route(
    method: Patch,
    path: "/patch",
    controller: api_controller.patch,
    middleware: [],
  )
  |> route(
    method: Delete,
    path: "/delete",
    controller: api_controller.delete,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/json",
    controller: api_controller.json_endpoint,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/text",
    controller: api_controller.text,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/uuid",
    controller: api_controller.uuid,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/status/:code",
    controller: api_controller.status,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/large",
    controller: api_controller.large,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/empty",
    controller: api_controller.empty,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/slow",
    controller: api_controller.slow,
    middleware: [],
  )
  // Compression endpoints
  |> route(
    method: Get,
    path: "/gzip",
    controller: api_controller.gzip,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/deflate",
    controller: api_controller.deflate,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/identity",
    controller: api_controller.identity,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/unknown-encoding",
    controller: api_controller.unknown_encoding,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/corrupted-gzip",
    controller: api_controller.corrupted_gzip,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/echo-accept-encoding",
    controller: api_controller.echo_accept_encoding,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/non-utf8-error",
    controller: api_controller.non_utf8_error,
    middleware: [],
  )
  // Redirect endpoints
  |> route(
    method: Get,
    path: "/redirect/301",
    controller: api_controller.redirect_301,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/redirect/302",
    controller: api_controller.redirect_302,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/redirect/303",
    controller: api_controller.redirect_303,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/redirect/307",
    controller: api_controller.redirect_307,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/redirect/308",
    controller: api_controller.redirect_308,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/redirect/chain",
    controller: api_controller.redirect_chain,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/redirect/chain/2",
    controller: api_controller.redirect_chain_2,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/redirect/absolute",
    controller: api_controller.redirect_absolute,
    middleware: [],
  )
  // Streaming endpoints
  |> route(
    method: Get,
    path: "/stream/fast",
    controller: stream_controller.stream_fast,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/stream/slow",
    controller: stream_controller.stream_slow,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/stream/burst",
    controller: stream_controller.stream_burst,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/stream/error",
    controller: stream_controller.stream_error,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/stream/huge",
    controller: stream_controller.stream_huge,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/stream/drop",
    controller: stream_controller.stream_drop,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/stream/json",
    controller: stream_controller.stream_json,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/stream/binary",
    controller: stream_controller.stream_binary,
    middleware: [],
  )
  // Compressed streaming endpoints
  |> route(
    method: Get,
    path: "/stream/gzip",
    controller: stream_controller.stream_gzip,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/stream/deflate",
    controller: stream_controller.stream_deflate,
    middleware: [],
  )
  |> route(
    method: Get,
    path: "/stream/unknown-encoding",
    controller: stream_controller.stream_unknown_encoding,
    middleware: [],
  )
}

/// Creates the router of config mode.
///
/// The router has one catch-all route for each of GET, POST, PUT, DELETE and
/// PATCH. Each one sends the request to `config_controller.handle`, which
/// answers from the routes in the `MockConfigContext`. The router has no
/// built-in endpoints. `server.start_with_config` uses this router.
///
/// ## Returns
///
/// A router that needs a `MockConfigContext` as its context and
/// `EmptyServices`.
///
/// ## Example
///
/// ### Serve config-mode routes from your own server <a href="https://github.com/TrustBound/dream_mock_server/blob/1.1.1/test/snippets/own_config_server.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream/servers/mist/server as dream_server
/// import dream_mock_server/config.{type MockRoute, MockConfigContext}
/// import dream_mock_server/router
/// import gleam/otp/actor
///
/// pub fn start_own_config_server(
///   port: Int,
///   routes: List(MockRoute),
/// ) -> Result(dream_server.ServerHandle, actor.StartError) {
///   dream_server.new()
///   |> dream_server.context(MockConfigContext(routes: routes))
///   |> dream_server.router(router.create_config_router())
///   |> dream_server.bind("localhost")
///   |> dream_server.listen_with_handle(port)
/// }
/// ```
///
/// ## See Also
///
/// - `dream_mock_server/server.start_with_config`
/// - `dream_mock_server/config.MockRoute`
pub fn create_config_router() -> Router(MockConfigContext, EmptyServices) {
  router()
  |> route(
    method: Get,
    path: "/**path",
    controller: config_controller.handle,
    middleware: [],
  )
  |> route(
    method: Post,
    path: "/**path",
    controller: config_controller.handle,
    middleware: [],
  )
  |> route(
    method: Put,
    path: "/**path",
    controller: config_controller.handle,
    middleware: [],
  )
  |> route(
    method: Delete,
    path: "/**path",
    controller: config_controller.handle,
    middleware: [],
  )
  |> route(
    method: Patch,
    path: "/**path",
    controller: config_controller.handle,
    middleware: [],
  )
}
