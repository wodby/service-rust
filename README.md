# Rust service for Kubernetes on Wodby

Build and run Rust applications on Kubernetes with Wodby.

This repository defines the Wodby service manifests and operational
configuration for Rust.

- [Browse Wodby services](https://wodby.com/services)
- [Wodby service documentation](https://wodby.com/docs/2.0/services/)
- [Service manifest reference](https://wodby.com/docs/2.0/services/template/)

## Start with a boilerplate

Use one of the boilerplates exposed by this service to start with compatible
build configuration and Wodby CI:

- [Rust boilerplate](https://github.com/wodby/rust-boilerplate)

## Wodby stacks using this service

- [Rust application stack](https://github.com/wodby/stack-rust)

## Service overview

| Property | Manifest configuration |
| --- | --- |
| Service name | `rust` |
| Type | Application service |
| Versions | `1` (latest stable Rust) |
| Workloads | `main` (Deployment), primary; scalable |
| Containers | `rust` using `wodby/rust`, build target |
| Endpoints | `rust`: HTTP 8080 (main) |
| Service links | DBMS (`db`), optional, Mail Transfer Agent (`sendmail`), optional, Redis, optional |
| Application build | Git source connection enabled; Dockerfile: `Dockerfile`; boilerplates: Rust boilerplate |
| Helm | chart `oci://registry-1.docker.io/wodby/stateless`; version `0.4.0` |
| Configuration | 1 integration slots |

## Use this service

Use this service through [Rust application stack](https://github.com/wodby/stack-rust), or reference `rust` from a custom
Wodby stack.

A service is a reusable component and does not deploy by itself. The stack
defines its links, settings, versions, resources, and relationship to the rest
of the application.

## Maintain a custom version

1. Fork this repository.
2. Edit the service manifest and referenced files.
3. Import the repository as a [Git-backed service](https://wodby.com/docs/2.0/services/create/#create-a-git-backed-service).
4. Reference the service from a stack manifest.

Keep service, workload, container, endpoint, link, volume, config, and
derivative names stable unless dependent stacks and app-level overrides are
updated at the same time.

Validate the manifests with:

```bash
wodby service validate-manifest service.yml --org <org-id>
```

See the [service manifest reference](https://wodby.com/docs/2.0/services/template/) and the [managed services index](https://github.com/wodby/services).

## Development workspaces

`workspace-rust prepare` downloads the project's crates and compiles it once.
`workspace-rust start` compiles and runs it, then compiles again and restarts the application
whenever a file in the checkout changes. `WORKSPACE_RUST_WATCH=0` turns that off.
`WORKSPACE_RUST_BIN` and `WORKSPACE_RUST_PACKAGE` select the binary when the project builds
several; `WORKSPACE_RUST_COMMAND` overrides startup.
`HOST` and `PORT` default to `0.0.0.0` and `8080`, but the application must read them.
A committed `Cargo.lock` is used with `--locked`, so it is never rewritten. Fix dependency
declarations deliberately with `cargo update` before retrying a failed preparation.

Requires a runtime image declaring workspace contract version 1. Ordinary and development option tags must use matching revisions.
