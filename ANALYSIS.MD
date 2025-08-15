# Weather MCP Server — Entry Flow Analysis

## Summary
- Rust MCP server exposing weather tools over `stdio` using `rmcp`.
- Async runtime via `tokio`; HTTP via `reqwest`; logging via `tracing`.
- Talks to National Weather Service API (`https://api.weather.gov`) with a custom user-agent.

## Entry Points
- Binary entry: `src/main.rs` with `#[tokio::main]`.
- `main()` boot sequence:
  - Initialize `tracing_subscriber` with `EnvFilter` (honors `RUST_LOG`; defaults include DEBUG directive in code).
  - Log startup: “Starting MCP server”.
  - Construct service: `let service = Weather::new().serve(stdio()).await?;`
    - `Weather::new()` builds a `reqwest::Client` with `USER_AGENT = "weather-app/1.0"`.
    - `.serve(stdio())` (from `rmcp::ServiceExt`) starts the MCP server over stdio.
  - Block until shutdown: `service.waiting().await?`.

## Server + Tools Wiring
- `#[tool(tool_box)] impl Weather { ... }` registers methods annotated with `#[tool(...)]` as MCP tools.
- `impl ServerHandler for Weather`:
  - `get_info()` returns `ServerInfo` with `instructions` and `ServerCapabilities` that enable tools.

## Exposed Tools
- `get_alerts(state: String) -> String`
  - Builds URL: `GET https://api.weather.gov/alerts/active?area={state}`.
  - Parses `AlertResponse` → formats human-readable text via `format_alerts`.
  - On error: logs and returns a friendly message string.
- `get_forecast(PointsRequest { latitude, longitude }) -> String`
  - `GET /points/{lat},{lon}` → read `properties.forecast` URL.
  - `GET {forecast_url}` → parse `GridPointsResponse` with `periods`.
  - Formats readable blocks via `format_forecast`.
  - On error: logs and returns a friendly message string.

## HTTP Flow + Error Handling
- Centralized in `Weather::make_request<T>(&self, url) -> Result<T, String>`:
  - Logs outbound URL and the received response (status, etc.).
  - Accepts only `StatusCode::OK`; otherwise returns `Err(String)` with status.
  - Deserializes JSON into caller-provided type `T`.
- Formatting helpers pre-size buffers and emit readable sections separated by `---`.

## Data Models (serde)
- Alerts: `AlertResponse` → `features: Vec<Feature>` → `FeatureProps` (event, area_desc, severity, status, headline).
- Points: `PointsRequest { latitude, longitude }`, `PointsResponse { properties: PointsProps { forecast } }`.
- Forecast: `GridPointsResponse { properties: GridPointsProps { periods: Vec<Period> } }` with temperature, wind, and short description.

## Files of Interest
- `src/main.rs`: models, tool implementations, server wiring, and entrypoint.
- `Cargo.toml`: deps and Rust edition (`2024`).
- `script.sh`: convenience commands to `cargo add` dependencies (not needed to run).

## How To Run
- Build and run: `cargo run` (starts MCP server listening over stdio).
- Control logs: set `RUST_LOG=info` or `RUST_LOG=debug`.
- Intended usage: launch as an MCP server; an MCP-compatible client connects over stdio and invokes tools `get_alerts` and `get_forecast`.

## Observability & Limits
- Logs via `tracing` include request URLs and response summaries; ANSI disabled, writes to stderr.
- Friendly user-facing strings on failures; no retries/backoff or explicit request timeouts configured.
- Uses a custom user-agent; no API key required for NWS.

## Dependencies (from Cargo.toml)
- `rmcp` (server, transport-io), `tokio` (macros, rt-multi-thread), `reqwest` (json), `serde` (+derive), `serde_json`, `anyhow`, `tracing`, `tracing-subscriber` (+env-filter).

## One-Liner Entry Flow
`cargo run` → `tokio` runtime → init `tracing` → `Weather::new()` → `serve(stdio())` → MCP tools available (`get_alerts`, `get_forecast`) → process requests until `service.waiting()` returns.

