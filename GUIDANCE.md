# Rust on Wodby

What Wodby sets up for an application that runs on this service. Check it before changing the build, the port or connection settings in the code.

## Build and start

The service's Dockerfile copies the repository to `/usr/src/app` and, when there is a `Cargo.toml` at its root:

1. runs `cargo build --release`, with `--locked` when `Cargo.lock` is committed;
2. installs the built binary as `/home/wodby/.cargo/bin/app`.

The container starts that binary as `app`. So with the service's Dockerfile the project must build exactly one binary, or name one with `default-run` in `Cargo.toml`. A pipeline that passes a Dockerfile from the repository (`wodby ci build rust -f Dockerfile`) uses that file instead; it must still end with a command that starts the server.

- The image is Alpine Linux: binaries are built for the `musl` target and linked statically. Crates that link OpenSSL build as is; other C libraries need a Dockerfile from the repository that installs their static packages.
- Commit `Cargo.lock`: an outdated lock file fails the build instead of being rewritten.
- The application must listen on port 8080, on all interfaces. That is the port of the service's HTTP endpoint. The service sets no `PORT` variable in a deployed environment: default to 8080 in the code.
- The container is ready when `GET /` on port 8080 answers 200. An application without a page at `/` stays unready and is never served.
- The service sets no other variable for the application and generates no configuration file.
- The service declares no volume of its own: files written inside the container are lost when it is replaced.

## Linked services

Links to other services reach the application as environment variables. Nothing in the image reads them: the application reads them itself. Do not hardcode hosts or credentials.

| Link | Variables |
| --- | --- |
| Database (MariaDB, MySQL or PostgreSQL) | `DB_HOST`, `DB_PORT`, `DB_NAME` (also `DB_DATABASE`), `DB_USERNAME`, `DB_PASSWORD`, `DB_DRIVER` (also `DB_CONNECTION`) |
| Mail | `SMTP_HOST`, `SMTP_PORT` |
| Redis or Valkey | `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` |
| OpenTelemetry Collector | `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL` (`http/protobuf`), `OTEL_EXPORTER_OTLP_HEADERS` (the Collector's ingest token) |

All links are optional. A variable is present only while its link exists and the linked service is enabled. The mail link carries no credentials. The OpenTelemetry variables are the standard SDK settings: an application or agent that uses an OpenTelemetry SDK exports to the Collector without further configuration; set `OTEL_SERVICE_NAME` to name the application in traces.

## Environment

- `WODBY_HOSTS` is a JSON array of the environment's hosts, not a comma-separated string. `WODBY_PRIMARY_HOST` and `WODBY_PRIMARY_URL` are the canonical ones for links generated outside a request.
- `WODBY_APP_SERVICE_NAME` is this service's host name inside the environment. Other services reach the application at that name on port 8080.
- `WODBY_ENV_TYPE` tells a development environment from a production-like one.

## In a development workspace

- The checkout is mounted at `/usr/src/app`. The application is compiled from it with `cargo build` (the debug profile) and run, and the checkout is watched: when a file changes, it is compiled again and the application is restarted with the new build, in the same container. Nothing has to be restarted or deployed for a code change. A build that fails leaves the previous build running; the compiler's errors are in the service's logs.
- Workspace setup downloads the crates and compiles the project once with `workspace-rust prepare`, so the first start only builds what changed. A compile error doesn't fail setup.
- `Cargo.toml` is required. A committed `Cargo.lock` is used with `--locked` and never rewritten: a missing or outdated entry fails the build and must be fixed in the repository with `cargo update`.
- The binary run is the project's only one, or its `default-run` one. `WORKSPACE_RUST_BIN` on the service selects another binary and `WORKSPACE_RUST_PACKAGE` a workspace member. `WORKSPACE_RUST_COMMAND` replaces the start command.
- `HOST` and `PORT` are set, to `0.0.0.0` and `8080` by default. The application must read them or listen on 8080 anyway.
- Build artifacts and downloaded crates are in `.wodby-workspace/` in the checkout (`CARGO_TARGET_DIR` and `CARGO_HOME` point there). `.wodby-workspace/` is kept out of Git status without touching `.gitignore`. A `cargo build` run by hand in the checkout uses `target/` as usual, which the watcher ignores.
- A change to variables or linked services still needs a deployment of the environment.

## Check the result

- `curl -s -o /dev/null -w '%{http_code}' localhost:8080` from the container shows whether the application answers on the expected port.
- `cargo check && cargo clippy` in the checkout shows compile errors and lints at once; the service's logs show them too when a change does not appear.
