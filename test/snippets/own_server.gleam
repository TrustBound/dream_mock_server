//// Docs: router.create_router
////
//// Serves the built-in endpoints from a Dream server that you set up.

import dream/servers/mist/server as dream_server
import dream_mock_server/router
import gleam/otp/actor

pub fn start_own_server(
  port: Int,
) -> Result(dream_server.ServerHandle, actor.StartError) {
  dream_server.new()
  |> dream_server.router(router.create_router())
  |> dream_server.bind("localhost")
  |> dream_server.listen_with_handle(port)
}
