//// Controllers for the info page and the streaming endpoints.
////
//// `router.create_router` sends requests to these functions. Each streaming
//// controller returns a `Stream` body that makes its chunks with fixed content
//// and fixed delays, so a test of an HTTP client gets the same chunks in each
//// run. The process that sends the response sleeps between the chunks.

import dream/context.{type EmptyContext}
import dream/http/header.{Header}
import dream/http/request.{type Request}
import dream/http/response.{type Response, stream_response, text_response}
import dream/http/status
import dream/router.{type EmptyServices}
import dream_mock_server/compression
import dream_mock_server/views/index_view
import gleam/bit_array
import gleam/erlang/process
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/yielder

/// Handles `GET /`: returns a text page that lists the endpoints.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with a `text/plain; charset=utf-8` body: the page of
/// `index_view.format_index`.
///
/// ## See Also
///
/// - `dream_mock_server/views/index_view.format_index`
pub fn index(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  text_response(status.ok, index_view.format_index())
}

/// Handles `GET /stream/fast`: streams 10 chunks, one each 100 ms.
///
/// Each chunk is `Chunk N\n` for N from 1 to 10. The stream takes about one
/// second. Use it to check that a client reads a stream.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with `Content-Type: text/plain` and a `Stream` body.
pub fn stream_fast(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let stream =
    yielder.range(1, 10)
    |> yielder.map(create_fast_chunk)

  stream_response(status.ok, stream, "text/plain")
}

fn create_fast_chunk(n: Int) -> BitArray {
  process.sleep(100)
  let line = "Chunk " <> int.to_string(n) <> "\n"
  bit_array.from_string(line)
}

/// Handles `GET /stream/slow`: streams 5 chunks, one each 2 seconds.
///
/// Each chunk is `Chunk N\n` for N from 1 to 5. The stream takes about ten
/// seconds. Use it to check the timeouts of a client.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with `Content-Type: text/plain` and a `Stream` body.
pub fn stream_slow(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let stream =
    yielder.range(1, 5)
    |> yielder.map(create_slow_chunk)

  stream_response(status.ok, stream, "text/plain")
}

fn create_slow_chunk(n: Int) -> BitArray {
  process.sleep(2000)
  let line = "Chunk " <> int.to_string(n) <> "\n"
  bit_array.from_string(line)
}

/// Handles `GET /stream/burst`: streams 7 chunks with different delays.
///
/// Each chunk is `Burst N\n` for N from 1 to 7. The delays before the chunks
/// are always 100, 500, 200, 400, 100, 300 and 200 ms, so the timing is the
/// same in each run. Use it to check how a client buffers a stream.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with `Content-Type: text/plain` and a `Stream` body.
pub fn stream_burst(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  // Fixed pattern: 7 chunks with varying delays for deterministic testing
  let delays = [100, 500, 200, 400, 100, 300, 200]

  let stream =
    list.index_map(delays, create_indexed_delay)
    |> yielder.from_list
    |> yielder.map(create_burst_chunk)

  stream_response(status.ok, stream, "text/plain")
}

fn create_indexed_delay(delay: Int, idx: Int) -> #(Int, Int) {
  #(idx + 1, delay)
}

fn create_burst_chunk(pair: #(Int, Int)) -> BitArray {
  let #(n, delay) = pair
  process.sleep(delay)
  let line = "Burst " <> int.to_string(n) <> "\n"
  bit_array.from_string(line)
}

/// Handles `GET /stream/error`: streams 3 chunks with status 500.
///
/// Each chunk is `Error test chunk N\n` for N from 1 to 3, one each 100 ms.
/// Use it to check how a client handles an error status on a stream.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 500 with `Content-Type: text/plain` and a `Stream` body.
pub fn stream_error(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let stream =
    yielder.range(1, 3)
    |> yielder.map(create_error_chunk)

  // Return 500 status with partial content to simulate mid-stream error
  stream_response(status.internal_server_error, stream, "text/plain")
}

fn create_error_chunk(n: Int) -> BitArray {
  process.sleep(100)
  let line = "Error test chunk " <> int.to_string(n) <> "\n"
  bit_array.from_string(line)
}

/// Handles `GET /stream/drop`: streams 2 chunks, then closes the connection.
///
/// The chunks are `Drop chunk 1\n` and `Drop chunk 2\n`, one each 50 ms. When
/// the server reads the third chunk, the stream panics. The panic stops the
/// process that handles the request, so the TCP connection closes before the
/// stream ends. Use it to check that a client reports a connection that
/// closes mid-stream.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with `Content-Type: text/plain` and a `Stream` body that
/// panics after its second chunk.
pub fn stream_drop(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let stream =
    yielder.range(1, 5)
    |> yielder.map(fn(n) {
      case n > 2 {
        True -> panic as "intentional crash to drop connection"
        False -> {
          process.sleep(50)
          let line = "Drop chunk " <> int.to_string(n) <> "\n"
          bit_array.from_string(line)
        }
      }
    })

  stream_response(status.ok, stream, "text/plain")
}

/// Handles `GET /stream/huge`: streams 100 chunks, one each 10 ms.
///
/// Each chunk is `Huge chunk N\n` for N from 1 to 100. Use it to check memory
/// use and speed when a client reads many chunks.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with `Content-Type: text/plain` and a `Stream` body.
pub fn stream_huge(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let stream =
    yielder.range(1, 100)
    |> yielder.map(create_huge_chunk)

  stream_response(status.ok, stream, "text/plain")
}

fn create_huge_chunk(n: Int) -> BitArray {
  process.sleep(10)
  let line = "Huge chunk " <> int.to_string(n) <> "\n"
  bit_array.from_string(line)
}

/// Handles `GET /stream/json`: streams 5 JSON objects, one on each line.
///
/// Each chunk is `{"event":"chunk","number":N,"message":"JSON event N"}`
/// and a newline, for N from 1 to 5, one each 200 ms.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with `Content-Type: application/json` and a `Stream` body.
pub fn stream_json(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let stream =
    yielder.range(1, 5)
    |> yielder.map(create_json_chunk)

  stream_response(status.ok, stream, "application/json")
}

fn create_json_chunk(n: Int) -> BitArray {
  process.sleep(200)
  let json_obj =
    json.object([
      #("event", json.string("chunk")),
      #("number", json.int(n)),
      #("message", json.string("JSON event " <> int.to_string(n))),
    ])
    |> json.to_string
  bit_array.from_string(json_obj <> "\n")
}

/// Handles `GET /stream/binary`: streams 256 chunks of binary data.
///
/// For each byte value from 0 to 255, one chunk holds four bytes of that
/// value, one chunk each 10 ms. Use it to check that a client reads bytes
/// that are not text.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with `Content-Type: application/octet-stream` and a `Stream`
/// body.
pub fn stream_binary(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let stream =
    yielder.range(0, 255)
    |> yielder.map(create_binary_chunk)

  stream_response(status.ok, stream, "application/octet-stream")
}

fn create_binary_chunk(n: Int) -> BitArray {
  process.sleep(10)
  <<n:8, n:8, n:8, n:8>>
}

/// Handles `GET /stream/gzip`: streams one gzip stream in chunks.
///
/// The text `Chunk 1\n` to `Chunk 5\n` is compressed as one gzip stream and
/// sent as 6 chunks, one each 50 ms. Use it to check that a client
/// decompresses a gzip stream chunk by chunk.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the headers `Content-Type: text/plain` and
/// `Content-Encoding: gzip`, and a `Stream` body.
///
/// ## See Also
///
/// - `dream_mock_server/compression.gzip_compress_chunks`
pub fn stream_gzip(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let plain_chunks =
    yielder.range(1, 5)
    |> yielder.map(fn(n) {
      bit_array.from_string("Chunk " <> int.to_string(n) <> "\n")
    })
    |> yielder.to_list

  let compressed_chunks = compression.gzip_compress_chunks(plain_chunks)

  let stream =
    yielder.from_list(compressed_chunks)
    |> yielder.map(fn(chunk) {
      process.sleep(50)
      chunk
    })

  response.Response(
    status: status.ok,
    body: response.Stream(stream),
    headers: [
      Header("Content-Type", "text/plain"),
      Header("Content-Encoding", "gzip"),
    ],
    cookies: [],
    content_type: option.Some("text/plain"),
  )
}

/// Handles `GET /stream/deflate`: streams one deflate stream in chunks.
///
/// The text `Chunk 1\n` to `Chunk 5\n` is compressed as one zlib stream and
/// sent as 6 chunks, one each 50 ms.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the headers `Content-Type: text/plain` and
/// `Content-Encoding: deflate`, and a `Stream` body.
///
/// ## See Also
///
/// - `dream_mock_server/compression.deflate_compress_chunks`
pub fn stream_deflate(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let plain_chunks =
    yielder.range(1, 5)
    |> yielder.map(fn(n) {
      bit_array.from_string("Chunk " <> int.to_string(n) <> "\n")
    })
    |> yielder.to_list

  let compressed_chunks = compression.deflate_compress_chunks(plain_chunks)

  let stream =
    yielder.from_list(compressed_chunks)
    |> yielder.map(fn(chunk) {
      process.sleep(50)
      chunk
    })

  response.Response(
    status: status.ok,
    body: response.Stream(stream),
    headers: [
      Header("Content-Type", "text/plain"),
      Header("Content-Encoding", "deflate"),
    ],
    cookies: [],
    content_type: option.Some("text/plain"),
  )
}

/// Handles `GET /stream/unknown-encoding`: streams plain text with `Content-Encoding: br`.
///
/// The chunks are `Raw 1\n` to `Raw 5\n`, one each 50 ms, and are not
/// compressed. Use it to check what a client does with a streamed encoding
/// that it does not support.
///
/// ## Parameters
///
/// - `_request`: Not used.
/// - `_context`: Not used.
/// - `_services`: Not used.
///
/// ## Returns
///
/// Status 200 with the headers `Content-Type: text/plain` and
/// `Content-Encoding: br`, and a `Stream` body.
pub fn stream_unknown_encoding(
  _request: Request,
  _context: EmptyContext,
  _services: EmptyServices,
) -> Response {
  let stream =
    yielder.range(1, 5)
    |> yielder.map(fn(n) {
      process.sleep(50)
      bit_array.from_string("Raw " <> int.to_string(n) <> "\n")
    })

  response.Response(
    status: status.ok,
    body: response.Stream(stream),
    headers: [
      Header("Content-Type", "text/plain"),
      Header("Content-Encoding", "br"),
    ],
    cookies: [],
    content_type: option.Some("text/plain"),
  )
}
