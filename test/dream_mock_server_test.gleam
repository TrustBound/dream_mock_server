//// Runs every test suite with the dream_test runner and measures the line
//// coverage of `src/`. The run fails when a test fails or when the
//// coverage is below 100%.

import config_mode_test
import dream_mock_server/compression_test
import dream_mock_server/controllers/api_controller_test
import dream_mock_server/controllers/config_controller_test
import dream_mock_server/controllers/stream_controller_test
import dream_mock_server/router_test
import dream_mock_server/views/api_view_test
import dream_mock_server/views/index_view_test
import dream_test/coverage
import dream_test/reporters/bdd
import dream_test/reporters/progress
import dream_test/runner
import features/mock_server_feature
import server_test
import snippets/integration_testing
import snippets_test
import standalone_test

pub fn main() {
  runner.new([
    api_view_test.tests(),
    index_view_test.tests(),
    compression_test.tests(),
    api_controller_test.tests(),
    config_controller_test.tests(),
    stream_controller_test.tests(),
    router_test.tests(),
    server_test.tests(),
    config_mode_test.tests(),
    standalone_test.tests(),
    snippets_test.tests(),
    integration_testing.tests(),
    mock_server_feature.tests(),
  ])
  // The streaming endpoints sleep between chunks: /stream/slow takes about
  // ten seconds to read.
  |> runner.default_timeout_ms(30_000)
  |> runner.progress_reporter(progress.new())
  |> runner.results_reporters([bdd.new() |> bdd.color()])
  |> runner.coverage(
    coverage.new()
    |> coverage.show_missing()
    |> coverage.minimum_percent(100.0)
    |> coverage.json_path("build/coverage/coverage.json"),
  )
  |> runner.exit_on_failure()
  |> runner.run()
}
