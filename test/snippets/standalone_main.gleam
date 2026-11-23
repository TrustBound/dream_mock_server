//// Doc comment: standalone.main

import gleam/erlang/process
import standalone

/// Runs the mock server on port 3004 in a new process. Kill the process to
/// stop the server.
pub fn start_in_background() -> process.Pid {
  process.spawn_unlinked(standalone.main)
}
