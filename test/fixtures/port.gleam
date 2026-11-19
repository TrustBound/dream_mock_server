//// Free TCP ports for the tests that start a server.

/// Returns a TCP port that no other test in this run got before.
@external(erlang, "port_ffi", "free_port")
pub fn free_port() -> Int
