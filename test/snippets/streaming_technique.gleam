//// README: Streaming Technique

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
