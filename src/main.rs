//! gw2wrapper: minimal, secure Guild Wars 2 API wrapper.

use std::io::{self, Write as _};
use std::process::ExitCode;

/// Writes the greeting; a failed write (e.g. closed pipe) yields a non-zero exit instead of a panic.
fn main() -> ExitCode {
    writeln!(io::stdout().lock(), "Hello, World!").map_or(ExitCode::FAILURE, |()| ExitCode::SUCCESS)
}
