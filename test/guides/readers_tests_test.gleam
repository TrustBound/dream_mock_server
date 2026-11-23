//// Runs the readers' test modules that the guides show, as the guides show
//// them.

import dream_test/suite.{type TestSuite}
import snippets/guide_failures_testing
import snippets/guide_getting_started_testing
import snippets/guide_run_testing
import snippets/guide_stand_in_testing

pub fn getting_started() -> TestSuite {
  guide_getting_started_testing.tests()
}

pub fn failures() -> TestSuite {
  guide_failures_testing.tests()
}

pub fn stand_in() -> TestSuite {
  guide_stand_in_testing.tests()
}

pub fn run_the_server() -> TestSuite {
  guide_run_testing.tests()
}
