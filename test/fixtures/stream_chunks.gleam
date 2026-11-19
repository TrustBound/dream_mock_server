//// Expected chunks of the long streaming endpoints.

import gleam/bit_array
import gleam/int
import gleam/list
import gleam/yielder

/// The chunks of `/stream/huge`: `Huge chunk 1` to `Huge chunk 100`, each
/// with a newline.
pub fn huge_chunks() -> List(BitArray) {
  yielder.range(1, 100)
  |> yielder.to_list
  |> list.map(fn(number) {
    bit_array.from_string("Huge chunk " <> int.to_string(number) <> "\n")
  })
}

/// The chunks of `/stream/binary`: for each byte value from 0 to 255, four
/// bytes of that value.
pub fn binary_chunks() -> List(BitArray) {
  yielder.range(0, 255)
  |> yielder.to_list
  |> list.map(fn(byte) { <<byte:8, byte:8, byte:8, byte:8>> })
}
