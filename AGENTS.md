# Repository Guidelines

## Project Structure & Module Organization
- `src/main.rs`: MCP server entrypoint, tool definitions, models, and HTTP logic.
- `Cargo.toml`: Dependencies and Rust edition.
- `script.sh`: Helper to add dependencies (not required to run).
- Suggested: place future modules under `src/` (e.g., `src/weather/`, `src/http.rs`). Integration tests under `tests/`.

## Build, Test, and Development Commands
- Build: `cargo build` — compiles the binary.
- Run: `RUST_LOG=info cargo run` — starts the MCP server over `stdio`.
- Debug logs: `RUST_LOG=debug cargo run` — verbose tracing.
- Test: `cargo test` — runs unit/integration tests (none yet).
- Lint/format (recommended): `cargo fmt --all` and `cargo clippy -- -D warnings`.

## Coding Style & Naming Conventions
- Rust 2024 edition; format with `rustfmt` (4‑space indentation).
- Naming: `snake_case` for functions/vars, `PascalCase` for types, `SCREAMING_SNAKE_CASE` for consts.
- Errors: prefer `anyhow::Result` at boundaries; return typed errors internally where practical.
- Logging: use `tracing` with contextual spans/fields; avoid ANSI output (stderr is preconfigured without ANSI).

## Testing Guidelines
- Unit tests: colocate with modules using `#[cfg(test)] mod tests { ... }`.
- Integration tests: create files in `tests/` (e.g., `tests/forecast.rs`).
- Name tests descriptively (e.g., `fetches_forecast_for_valid_points`).
- Mock HTTP when possible; avoid hitting `api.weather.gov` in CI.

## Commit & Pull Request Guidelines
- No existing history; adopt Conventional Commits (e.g., `feat: add forecast tool`).
- PRs should include: purpose/summary, linked issues, test notes, and logs/output for new tools.
- Keep changes focused; update docs when altering tool behavior or server wiring.

## Agent-Specific Instructions
- Tools live in `impl Weather` with `#[tool(...)]` attributes. Document params with `schemars` where relevant.
- Extend `ServerHandler::get_info()` if capabilities/instructions change.
- HTTP: use the shared client in `Weather::new()`; set a clear `User-Agent` and handle non‑200 statuses.
