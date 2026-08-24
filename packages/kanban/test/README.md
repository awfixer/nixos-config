# Test Layout

- `test/core`: unit tests for core logic
- `test/cli`: unit tests for CLI parsing and output
- `test/integration`: integration tests that touch filesystem or process boundaries
- `test/fixtures`: stable test data
- `test/utilities`: shared test helpers

Use `*.test.ts` for deterministic unit tests. Use `*.integration.test.ts` for optional env-dependent tests.
