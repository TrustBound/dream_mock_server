//// Runs every test suite with the dream_test runner and measures the line
//// coverage of `src/`. The run fails when a test fails or when the
//// coverage is below 100%.

import config_mode_test
import dream_mock_server/compression_test
import dream_mock_server/internal/api_endpoints_test
import dream_mock_server/internal/built_in_endpoints_test
import dream_mock_server/internal/config_endpoint_test
import dream_mock_server/internal/message_test
import dream_mock_server/internal/mist_adapter_test
import dream_mock_server/internal/path_test
import dream_mock_server/internal/routes_test
import dream_mock_server/internal/standalone_runner_test
import dream_mock_server/internal/stream_endpoints_test
import dream_mock_server/views/api_view_test
import dream_mock_server/views/index_view_test
import dream_test/coverage
import dream_test/reporters/bdd
import dream_test/reporters/progress
import dream_test/runner
import features/mock_server_feature
import guides/failures_test
import guides/getting_started_test
import guides/readers_tests_test
import guides/run_the_server_test
import guides/stand_in_test
import server_test
import snippets/integration_testing
import snippets_test
import standalone_test

pub fn main() {
  runner.new([
    api_view_test.tests(),
    index_view_test.tests(),
    compression_test.tests(),
    path_test.tests(),
    message_test.tests(),
    api_endpoints_test.tests(),
    built_in_endpoints_test.tests(),
    config_endpoint_test.tests(),
    stream_endpoints_test.tests(),
    routes_test.tests(),
    mist_adapter_test.tests(),
    standalone_runner_test.tests(),
    server_test.tests(),
    config_mode_test.tests(),
    standalone_test.tests(),
    snippets_test.tests(),
    integration_testing.tests(),
    mock_server_feature.tests(),
    getting_started_test.tests(),
    failures_test.tests(),
    stand_in_test.tests(),
    readers_tests_test.getting_started(),
    readers_tests_test.failures(),
    readers_tests_test.stand_in(),
    readers_tests_test.run_the_server(),
    run_the_server_test.tests(),
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
