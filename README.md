# Weather MCP Server

[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/ci.yml)
![Rust Edition](https://img.shields.io/badge/Rust-2024-orange?logo=rust)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](#license)

Simple Model Context Protocol (MCP) server that exposes weather tools over stdio. It queries the National Weather Service API (api.weather.gov) and returns human‑readable alerts and forecasts. Built with Rust, tokio, reqwest, and rmcp.

## Features
- get_alerts: Fetches active alerts for a US state (e.g., "CA").
- get_forecast: Retrieves a point forecast given latitude/longitude.
- Shared HTTP client with custom User‑Agent and non‑200 handling.
- Structured logging via tracing; no ANSI in stderr output.

## Quick Start
- Prerequisites: Rust toolchain with 2024 edition support.
- Build: `cargo build`
- Run (info logs): `RUST_LOG=info cargo run`
- Run (debug logs): `RUST_LOG=debug cargo run`

This starts the MCP server over stdio; connect with any MCP‑compatible client.

## Usage (MCP)
- Transport: stdio. The binary reads requests from stdin and writes responses to stdout.
- Tools are implemented on `impl Weather` with `#[tool(...)]` attributes and are auto‑registered by rmcp.
- Server metadata comes from `ServerHandler::get_info()`.

### Exposed Tools
- get_alerts(state: String) -> String
  - Example: `state = "WA"` → returns formatted alerts or a friendly fallback.
- get_forecast({ latitude, longitude }) -> String
  - Example: `{ latitude: "47.60", longitude: "-122.33" }` → returns periodized forecast.

## Example MCP Client
Below is a minimal TypeScript example using an MCP SDK to launch this server over stdio and invoke a tool. Adjust imports to match your SDK version.

```ts
// TypeScript example (using an MCP client SDK)
// npm add @modelcontextprotocol/sdk
import { Client } from "@modelcontextprotocol/sdk/client";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/transport/stdio";

async function main() {
  const transport = new StdioClientTransport({
    command: process.platform === "win32" ? "cargo.exe" : "cargo",
    args: ["run"], // or path to the built binary
    env: { ...process.env, RUST_LOG: "info" },
  });

  const client = new Client({ name: "example-client", version: "0.1.0" }, transport);
  await client.connect();

  // Call get_alerts
  const alerts = await client.tools.call("get_alerts", { state: "CA" });
  console.log(alerts);

  // Call get_forecast
  const forecast = await client.tools.call("get_forecast", {
    latitude: "47.60",
    longitude: "-122.33",
  });
  console.log(forecast);
}

main().catch(console.error);
```

If you use another MCP client (e.g., Python), configure it to spawn the server via stdio with the command `cargo run` (or the built binary path) and then invoke tools `get_alerts` and `get_forecast` with the shown parameters.

## Development
- Project entrypoint: `src/main.rs` (server, tools, models, HTTP logic).
- Suggested modules: add new components under `src/` (e.g., `src/weather/`, `src/http.rs`).
- Tests: add unit tests in modules and integration tests under `tests/` (e.g., `tests/forecast.rs`).
- Extend `ServerHandler::get_info()` if capabilities or instructions change.

## Build, Test, and Lint
- Build: `cargo build`
- Run: `RUST_LOG=info cargo run`
- Debug logs: `RUST_LOG=debug cargo run`
- Tests: `cargo test` (mock HTTP where possible; avoid hitting api.weather.gov in CI)
- Format: `cargo fmt --all`
- Lint: `cargo clippy -- -D warnings`

## Architecture
- `Weather::new()`: constructs a shared `reqwest::Client` with `User-Agent`.
- `make_request<T>`: logs URL, checks status, deserializes JSON, returns typed result.
- Tools:
  - `get_alerts(state: String) -> String`
  - `get_forecast(PointsRequest { latitude, longitude }) -> String`
- Output is formatted into readable sections separated by `---`.

## Configuration & Logging
- Environment: set `RUST_LOG` to control verbosity (`info`, `debug`).
- Logging: `tracing` writes to stderr without ANSI; useful in CI logs.
- Network: this server depends on `api.weather.gov`; handle non‑200 statuses gracefully.

## Troubleshooting
- No output or tool calls fail:
  - Ensure your MCP client launches the server with stdio (`cargo run` or binary path).
  - Run with `RUST_LOG=debug` to see HTTP URLs and statuses.
- HTTP errors or timeouts:
  - Verify network access to `https://api.weather.gov`.
  - The server currently does not implement retries/backoff or custom timeouts.
- Tests hitting the network:
  - Prefer mocking HTTP in unit/integration tests to keep CI hermetic.

## Contributing
- Use Conventional Commits (e.g., `feat: add forecast tool`).
- Keep PRs focused; include purpose, logs/output for new tools, and test notes.
- Update docs when changing tool behavior or server wiring.

## License
Licensed under the MIT License. See `LICENSE` for details.

## Badges Note
- Replace `OWNER/REPO` in the CI badge with your GitHub org/repo and ensure a workflow exists at `.github/workflows/ci.yml`.
- Add crates.io/docs.rs badges if/when the crate is published.

