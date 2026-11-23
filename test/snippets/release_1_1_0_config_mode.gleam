//// Release 1.1.0: Start config mode
////
//// One prefix route for any method, started with start_with_config.

import dream_mock_server/config.{MockRoute, Prefix}
import dream_mock_server/server
import gleam/option.{None}
import gleam/otp/actor

pub fn start_chat_mock(
  port: Int,
) -> Result(server.ServerHandle, actor.StartError) {
  let config = [
    MockRoute(
      path: "/v1/chat/completions",
      path_match: Prefix,
      method: None,
      status: 200,
      body: "{\"choices\":[{\"message\":{\"content\":\"\"}}]}",
    ),
  ]

  // Run tests against http://127.0.0.1:<port>,
  // then call server.stop(handle).
  server.start_with_config(port, config)
}
