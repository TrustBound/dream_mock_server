//// The program of Step 3 of the guide "Run the server while you develop",
//// under the module name that the guide runs: `gleam run -m dev_chat_api`.
//// `scripts/run-server-smoke.sh` runs it.

import snippets/guide_run_dev_stand_in

/// Runs the chat API stand-in on port 4010 until you stop it.
pub fn main() -> Nil {
  guide_run_dev_stand_in.main()
}
