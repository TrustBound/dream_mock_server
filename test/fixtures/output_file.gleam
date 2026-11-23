//// The output files of the guides, in `test/outputs/`. Each output block of
//// the guides is a copy of one of these files, and a test compares the file
//// with the real output.

import gleam/int
import gleam/list
import gleam/string

/// Reads `test/outputs/<name>.txt`. Returns an error that names the path
/// when the file can't be read.
pub fn read(name: String) -> Result(String, String) {
  read_file("test/outputs/" <> name <> ".txt")
}

/// Runs a shell script with `sh`, from the root of the package. Returns the
/// exit status and what the script printed to standard output.
@external(erlang, "output_file_ffi", "run_script")
pub fn run_script(path: String) -> #(Int, String)

/// Writes each row as `call  -> result`, with the arrows lined up two spaces
/// after the longest call, and a line break after each row.
pub fn table(rows: List(#(String, String))) -> String {
  let width =
    rows
    |> list.map(fn(row) { string.length(row.0) })
    |> list.fold(0, int.max)
  rows
  |> list.map(fn(row) {
    string.pad_end(row.0, width + 2, " ") <> "-> " <> row.1 <> "\n"
  })
  |> string.concat
}

@external(erlang, "output_file_ffi", "read")
fn read_file(path: String) -> Result(String, String)
