# Worker Config

`worker.yaml` is the checked-in Worker runtime config contract for this image.
Use it for image-level defaults and secret references that should travel with
the repo. Runtime platform values still win when the container is deployed.

## Shape

```yaml
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    APP_ENV: production
  secrets:
    DATABASE_URL:
      from: database-url
```

Keep `config.env` for non-sensitive defaults. Keep `config.secrets` for secret
references only, not literal secret values.

## Local Validation

Validate the manifest syntax before opening a PR:

```bash
yq e '.' worker.yaml
```

Refresh generated repo context after changing `worker.yaml` or this reference:

```bash
dev.kit repo
```

## Deployment Behavior

Deployment tooling should load `worker.yaml` by convention when no explicit
config file is supplied. If a target platform provides the same environment
variable, the platform value overrides the checked-in default.

Base Worker references:

- https://github.com/udx/worker/blob/latest/docs/config.md
- https://github.com/udx/worker/blob/latest/docs/secrets.md
- https://github.com/udx/worker/blob/latest/docs/deployment.md
