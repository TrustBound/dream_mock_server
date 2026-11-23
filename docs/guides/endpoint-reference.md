# Endpoint reference

This page lists every built-in endpoint of the server that `server.start(port)` and `make run` start, with its status, headers, body and timing. Every answer is the same in each run, so a test can compare it exactly. For how to use the endpoints in tests, read the guides: [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md) and [Test how your client handles failures](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/testing-failures.md). Config mode has no built-in endpoints. The [Stand in for a third-party API](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/stand-in-for-an-api.md) guide covers its rules.

## Table of Contents

- [How the server matches a request](#how-the-server-matches-a-request)
- [Info page](#info-page)
- [Echo endpoints](#echo-endpoints)
- [Fixed bodies and status codes](#fixed-bodies-and-status-codes)
- [Compression](#compression)
- [Redirects](#redirects)
- [Streams](#streams)
- [How streams are timed](#how-streams-are-timed)

## How the server matches a request

- A path matches by its segments. Empty segments don't count, so `/text/` and `//text` match `/text`.
- A path segment with one file extension matches without it: `/text.json` matches `/text`, and `/status/418.json` answers status 418.
- The query string isn't part of the match.
- A request with the method CONNECT, TRACE or a method that isn't standard is handled as GET.
- A request that matches no endpoint gets status 404 with the `text/plain; charset=utf-8` body `Route not found`. That includes a request with the wrong method, such as `GET /post`, and every HEAD and OPTIONS request.
- The server reads the request body only when an endpoint matches. A body larger than 10 MB, or a body it can't read, gets status 400 with an empty body.
- A body that isn't streamed goes out with a `content-length` header. A streamed body goes out with chunked transfer encoding, one chunk at a time.

In the tables, `text/plain; charset=utf-8` and `application/json; charset=utf-8` are the full `Content-Type` values.

## Info page

| Request | Status | Content-Type | Body |
|:---|:---|:---|:---|
| `GET /` | 200 | `text/plain; charset=utf-8` | A text page that lists every endpoint on this page under the headings `Info Page`, `Non-Streaming Endpoints`, `Compression Endpoints`, `Redirect Endpoints` and `Streaming Endpoints`. Each endpoint has its method and path on one line, and what it returns on the next line. The page names no port. It is the result of `index_view.format_index()`. |

## Echo endpoints

These endpoints answer with parts of the request, so a test can check what a client sent. The functions of `dream_mock_server/views/api_view` build the same bodies.

| Request | Status | Content-Type | Body | Built by |
|:---|:---|:---|:---|:---|
| `GET /get` | 200 | `application/json; charset=utf-8` | `{"method":"GET","url":"/get","query":"<raw query>","headers":[]}`. The `query` is empty when there's none. The `headers` field is always an empty list. | `api_view.get_to_json(path, query)` |
| `POST /post` | 201 | `application/json; charset=utf-8` | `{"method":"POST","url":"/post","data":"<request body>"}` | `api_view.post_to_json(path, body)` |
| `PUT /put` | 200 | `application/json; charset=utf-8` | `{"method":"PUT","url":"/put","data":"<request body>"}` | `api_view.put_to_json(path, body)` |
| `PATCH /patch` | 200 | `application/json; charset=utf-8` | `{"method":"PATCH","url":"/patch","data":"<request body>"}` | `api_view.patch_to_json(path, body)` |
| `DELETE /delete` | 200 | `application/json; charset=utf-8` | `{"method":"DELETE","url":"/delete"}` | `api_view.delete_to_json(path)` |
| `POST /content-type` | 200 | `text/plain; charset=utf-8` | The `Content-Type` header of the request, or empty when there's none | |
| `GET /echo-accept-encoding` | 200 | `text/plain; charset=utf-8` | The `Accept-Encoding` header of the request, or empty when there's none. The header name matches in any letter case. | |

The `url` field holds the request path as the server got it, so `/post/` echoes `"url":"/post/"`. When the body of `POST /post`, `PUT /put` or `PATCH /patch` isn't valid UTF-8, the answer is status 400 with the `application/json; charset=utf-8` body `{"error":"Request body is not UTF-8 text"}`.

## Fixed bodies and status codes

| Request | Status | Content-Type | Body | Notes |
|:---|:---|:---|:---|:---|
| `GET /json` | 200 | `application/json; charset=utf-8` | `{"message":"Hello, World!","success":true}` | `api_view.simple_json_to_string()` |
| `GET /text` | 200 | `text/plain; charset=utf-8` | `Hello, World!` | `api_view.text_to_string()` |
| `GET /uuid` | 200 | `application/json; charset=utf-8` | `{"uuid":"123e4567-e89b-12d3-a456-426614174000"}` | Always the same UUID. `api_view.uuid_to_json()` |
| `GET /status/:code` | `code` | `application/json; charset=utf-8` | `{"status":<code>}` | `api_view.status_to_json(code)`. When `code` isn't an integer: status 400 with `{"error":"code must be an integer"}`, from `api_view.error_to_json(message)`. |
| `GET /empty` | 200 | `text/plain; charset=utf-8` | Empty | |
| `GET /large` | 200 | `text/plain; charset=utf-8` | 20,000 copies of the line `This is a repeated line to create a large response body.`, 1,140,000 bytes | Sent in one piece, not streamed |
| `GET /slow` | 200 | `text/plain; charset=utf-8` | `Slow response` | Answers after 5 seconds |
| `GET /non-utf8-error` | 400 | `text/plain` | `Error: ` and the bytes 0xC0, 0xC1, 0xFE, 0xFF, which aren't valid UTF-8 | 11 bytes |

## Compression

| Request | Status | Content-Type | Content-Encoding | Body |
|:---|:---|:---|:---|:---|
| `GET /gzip` | 200 | `text/plain` | `gzip` | `Hello, World!` compressed with gzip, the bytes of `compression.gzip_compress(<<"Hello, World!">>)` |
| `GET /deflate` | 200 | `text/plain` | `deflate` | `Hello, World!` compressed in the zlib format, the bytes of `compression.deflate_compress(<<"Hello, World!">>)` |
| `GET /identity` | 200 | `text/plain; charset=utf-8` | `identity` | `Hello, World!`, not compressed |
| `GET /unknown-encoding` | 200 | `text/plain; charset=utf-8` | `br` | `raw-uncompressed-bytes`, not compressed |
| `GET /corrupted-gzip` | 200 | `text/plain` | `gzip` | `this is not valid gzip data at all`, which isn't gzip |

The compressed streams are in [Streams](#streams).

## Redirects

Each redirect has a `Location` header, no `Content-Type` and an empty body.

| Request | Status | Location |
|:---|:---|:---|
| `GET /redirect/301` | 301 | `/text` |
| `GET /redirect/302` | 302 | `/text` |
| `GET /redirect/303` | 303 | `/text` |
| `GET /redirect/307` | 307 | `/text` |
| `GET /redirect/308` | 308 | `/text` |
| `GET /redirect/chain` | 302 | `/redirect/chain/2` |
| `GET /redirect/chain/2` | 302 | `/text` |
| `GET /redirect/absolute` | 302 | `http://<host>/text`, with the `Host` header of the request, or `localhost:9876` when the request has none |

## Streams

Each stream sends its status and headers first, and then its chunks, with a pause before each chunk.

| Request | Status | Content-Type | Chunks | Pause before each chunk | Total time |
|:---|:---|:---|:---|:---|:---|
| `GET /stream/fast` | 200 | `text/plain` | 10: `Chunk 1\n` to `Chunk 10\n` | 100 ms | About 1 s |
| `GET /stream/slow` | 200 | `text/plain` | 5: `Chunk 1\n` to `Chunk 5\n` | 2 s | About 10 s |
| `GET /stream/burst` | 200 | `text/plain` | 7: `Burst 1\n` to `Burst 7\n` | 100, 500, 200, 400, 100, 300 and 200 ms, in that order | About 1.8 s |
| `GET /stream/error` | 500 | `text/plain` | 3: `Error test chunk 1\n` to `Error test chunk 3\n` | 100 ms | About 0.3 s |
| `GET /stream/drop` | 200 | `text/plain` | 2: `Drop chunk 1\n` and `Drop chunk 2\n`, then the server closes the connection before the body ends | 50 ms | About 0.1 s |
| `GET /stream/huge` | 200 | `text/plain` | 100: `Huge chunk 1\n` to `Huge chunk 100\n` | 10 ms | About 1 s |
| `GET /stream/json` | 200 | `application/json` | 5: `{"event":"chunk","number":N,"message":"JSON event N"}` and a newline, for N from 1 to 5 | 200 ms | About 1 s |
| `GET /stream/binary` | 200 | `application/octet-stream` | 256: for each byte value from 0 to 255, four bytes of that value | 10 ms | About 2.6 s |
| `GET /stream/gzip` | 200 | `text/plain`, with `Content-Encoding: gzip` | 6: `Chunk 1\n` to `Chunk 5\n` as one gzip stream, one chunk for each line and one that ends the stream | 50 ms | About 0.3 s |
| `GET /stream/deflate` | 200 | `text/plain`, with `Content-Encoding: deflate` | 6: the same lines as one zlib stream | 50 ms | About 0.3 s |
| `GET /stream/unknown-encoding` | 200 | `text/plain`, with `Content-Encoding: br` | 5: `Raw 1\n` to `Raw 5\n`, not compressed | 50 ms | About 0.25 s |

Joined in order, the chunks of `/stream/gzip` are the bytes of `compression.gzip_compress_chunks` for the five lines, and the chunks of `/stream/deflate` are the bytes of `compression.deflate_compress_chunks`. Each chunk is flushed, so a client can decompress each one as it arrives.

`/stream/drop` closes the connection by stopping the process that sends the response. The server logs a crash report with the message `intentional crash to drop connection` each time.

## How streams are timed

A streaming endpoint makes its chunks with a `Yielder`. The server takes one element, sends it as a chunk, and only then takes the next one. So a sleep inside the yielder sets the pause before each chunk. This is how `/stream/fast` makes its chunks:

### Fast stream chunks <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/streaming_technique.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import gleam/bit_array
import gleam/erlang/process
import gleam/int
import gleam/yielder.{type Yielder}

/// The chunks of `GET /stream/fast`. The server sends one chunk for each
/// element, and asks for the next element only after it sent the last one.
pub fn fast_chunks() -> Yielder(BitArray) {
  yielder.range(1, 10)
  |> yielder.map(create_fast_chunk)
}

fn create_fast_chunk(number: Int) -> BitArray {
  process.sleep(100)
  let line = "Chunk " <> int.to_string(number) <> "\n"
  bit_array.from_string(line)
}
```

The pause runs on the server, before the chunk goes out. A client sees the same pauses, plus the time of the network. A client can still get two chunks at once: when it reads slower than the server writes, the bytes of several chunks wait in the network buffers, and one read gets all of them. So test that your client joins and splits the body correctly, and don't count on one chunk per read.
