ARG WODBY_BASE_IMAGE
FROM ${WODBY_BASE_IMAGE}

ARG COPY_FROM
ARG COPY_TO=/usr/src/app
COPY --chown=wodby:wodby ${COPY_FROM} ${COPY_TO}

# Build the project's only binary target, or its default-run one, and install it as `app`.
# A committed Cargo.lock is used as is; the build fails when it is out of date.
RUN set -e; \
    if [ -f Cargo.toml ]; then \
      locked=; \
      if [ -f Cargo.lock ]; then locked=--locked; fi; \
      cargo build --release ${locked} --message-format=json-render-diagnostics > /tmp/build.json; \
      binaries=$(jq -r 'select(.reason == "compiler-artifact" and .executable != null and (.target.kind | index("bin"))) | "\(.target.name)\t\(.executable)"' /tmp/build.json | sort -u); \
      if [ "$(printf '%s\n' "${binaries}" | grep -c .)" -gt 1 ]; then \
        default=$(cargo metadata --no-deps --format-version 1 ${locked} | jq -r --arg manifest "$(pwd -P)/Cargo.toml" '.packages[] | select(.manifest_path == $manifest) | .default_run // empty'); \
        binaries=$(printf '%s\n' "${binaries}" | awk -F '\t' -v name="${default}" '$1 == name'); \
      fi; \
      if [ "$(printf '%s\n' "${binaries}" | grep -c .)" -ne 1 ]; then \
        echo 'Build exactly one binary: set default-run in Cargo.toml or use a Dockerfile from the repository' >&2; \
        exit 1; \
      fi; \
      install -m 0755 "$(printf '%s\n' "${binaries}" | cut -f 2)" /home/wodby/.cargo/bin/app; \
      rm -rf target /tmp/build.json /home/wodby/.cargo/registry /home/wodby/.cargo/git; \
    fi

CMD ["app"]
