//// Connects the core of the mock server to `dream_http_server`.
////
//// `handler` gives the request function that `mist.new` takes. For each
//// request it builds the `RequestHead`, asks
//// `dream_mock_server/internal/routes.answer` for the response, and converts
//// that response for mist. It sends a `Bytes` body in one piece, and a
//// `Stream` body as a chunked response.

import dream_mock_server/internal/message.{
  type RequestHead, type Response, Bytes, RequestHead, Stream,
}
import dream_mock_server/internal/routes.{type Mode}
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request as HttpRequest}
import gleam/http/response.{type Response as HttpResponse}
import gleam/result
import gleam/yielder.{type Yielder}
import mist.{type Connection, type ResponseData}

/// The time to wait for the chunk process of a streamed response to start.
const chunk_process_start_timeout_ms = 1000

type DrainMessage {
  DrainNext
}

type DrainState {
  DrainState(remaining: Yielder(BitArray), subject: Subject(DrainMessage))
}

/// Creates the request function for `mist.new`.
///
/// ## Parameters
///
/// - `mode`: The endpoints of the server.
///
/// ## Returns
///
/// A function that answers each request with `routes.answer`. It reads the
/// request body, at most `routes.max_body_size` bytes, only when an endpoint
/// matches.
pub fn handler(
  mode: Mode,
) -> fn(HttpRequest(Connection)) -> HttpResponse(ResponseData) {
  fn(http_request: HttpRequest(Connection)) {
    let core_response =
      routes.answer(mode, request_head(http_request), fn() {
        read_body(http_request)
      })
    to_mist_response(http_request, core_response)
  }
}

fn request_head(http_request: HttpRequest(Connection)) -> RequestHead {
  RequestHead(
    method: http_request.method,
    path: http_request.path,
    query: http_request.query,
    headers: http_request.headers,
  )
}

fn read_body(http_request: HttpRequest(Connection)) -> Result(BitArray, Nil) {
  // Every read error gets the same 400 response, so the kind of error is
  // not needed.
  mist.read_body(http_request, max_body_limit: routes.max_body_size)
  |> result.map(fn(request_with_body) { request_with_body.body })
  |> result.replace_error(Nil)
}

fn to_mist_response(
  http_request: HttpRequest(Connection),
  core_response: Response,
) -> HttpResponse(ResponseData) {
  case core_response.body {
    Bytes(bytes) ->
      response.Response(
        status: core_response.status,
        headers: core_response.headers,
        body: mist.Bytes(bytes_tree.from_bit_array(bytes)),
      )
    Stream(chunks) -> stream_response(http_request, core_response, chunks)
  }
}

/// Sends a `Stream` body as a chunked response.
///
/// A chunk process reads the yielder and sends one chunk for each element.
/// It starts to read only after `mist.chunked` returned: on HTTP/1.1 mist
/// gives the socket to the chunk process after the process started, and a
/// stream that ended before that would make mist answer the request again.
/// So the chunk process sends its subject back to this process, and this
/// process sends the first `DrainNext` when `mist.chunked` is done.
fn stream_response(
  http_request: HttpRequest(Connection),
  core_response: Response,
  chunks: Yielder(BitArray),
) -> HttpResponse(ResponseData) {
  let head =
    response.Response(
      status: core_response.status,
      headers: core_response.headers,
      body: Nil,
    )
  let subject_reply = process.new_subject()
  let mist_response =
    mist.chunked(
      request: http_request,
      response: head,
      init: fn(subject) {
        process.send(subject_reply, subject)
        DrainState(remaining: chunks, subject: subject)
      },
      loop: drain_loop,
    )
  start_draining(subject_reply)
  mist_response
}

fn start_draining(subject_reply: Subject(Subject(DrainMessage))) -> Nil {
  // When mist cannot start the chunk process, it has already answered the
  // request with an error, and there is nothing to send.
  process.receive(subject_reply, chunk_process_start_timeout_ms)
  |> result.map(fn(subject) { process.send(subject, DrainNext) })
  |> result.unwrap(Nil)
}

fn drain_loop(
  state: DrainState,
  _message: DrainMessage,
  connection: Connection,
) -> mist.ChunkNext(DrainState) {
  case yielder.step(state.remaining) {
    yielder.Next(chunk, rest) -> send_chunk(state, chunk, rest, connection)
    yielder.Done -> mist.chunk_stop()
  }
}

fn send_chunk(
  state: DrainState,
  chunk: BitArray,
  rest: Yielder(BitArray),
  connection: Connection,
) -> mist.ChunkNext(DrainState) {
  // When the client has closed the connection, the stream stops.
  mist.send_chunk(connection, chunk)
  |> result.map(fn(_sent) {
    process.send(state.subject, DrainNext)
    mist.chunk_continue(DrainState(remaining: rest, subject: state.subject))
  })
  |> result.unwrap(mist.chunk_stop())
}
