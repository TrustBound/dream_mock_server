//// Docs: router.create_config_router
////
//// Serves config-mode routes from a Dream server that you set up.

import dream/servers/mist/server as dream_server
import dream_mock_server/config.{type MockRoute, MockConfigContext}
import dream_mock_server/router
import gleam/otp/actor

pub fn start_own_config_server(
  port: Int,
  routes: List(MockRoute),
) -> Result(dream_server.ServerHandle, actor.StartError) {
  dream_server.new()
  |> dream_server.context(MockConfigContext(routes: routes))
  |> dream_server.router(router.create_config_router())
  |> dream_server.bind("localhost")
  |> dream_server.listen_with_handle(port)
}
