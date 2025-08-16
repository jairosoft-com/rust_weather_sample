#!/bin/sh

# Add dependencies
cargo add rmcp@0.1.5 --features server,transport-io
cargo add tokio --features macros,rt-multi-thread
cargo add serde --features derive
cargo add serde_json
cargo add anyhow
cargo add tracing
cargo add tracing-subscriber --features env-filter
cargo add reqwest --features json