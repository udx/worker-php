<img src="assets/logo.svg" alt="UDX Worker PHP">

# UDX Worker PHP

[![Docker Pulls](https://img.shields.io/docker/pulls/usabilitydynamics/udx-worker-php.svg)](https://hub.docker.com/r/usabilitydynamics/udx-worker-php)
[![GitHub Release](https://img.shields.io/github/v/release/udx/worker-php?sort=semver)](https://github.com/udx/worker-php/releases/latest)
[![License](https://img.shields.io/github/license/udx/worker-php.svg)](LICENSE)

PHP runtime image built on UDX Worker with NGINX and PHP-FPM wired for `/var/www`.

[Quick Start](#quick-start) - [Runtime](#runtime) - [Development](#development) - [Deployment](#deployment) - [Rabbit CI](#rabbit-ci)

## Overview

`udx-worker-php` extends [`udx/worker`](https://github.com/udx/worker), published as `usabilitydynamics/udx-worker`, and keeps the worker runtime model while adding a PHP web stack:

- NGINX serves `/var/www`.
- PHP-FPM runs behind NGINX through a Unix socket.
- PHP CLI and common extensions are installed for application and automation workloads.
- Worker service definitions start both `php-fpm` and `nginx`.

Use this image as a base for PHP applications, automation jobs, or deployment workflows that need the Worker runtime contract.

## Quick Start

Requirements: Docker. Make is optional but recommended for local development.

Run the published image:

```bash
docker run -d \
  --name my-php-app \
  -p 8080:80 \
  -v "$(pwd)/my-php-app:/var/www" \
  usabilitydynamics/udx-worker-php:latest
```

Then open `http://localhost:8080`.

Build and run locally:

```bash
git clone https://github.com/udx/worker-php.git
cd worker-php

make build
make run HOST_PORT=8080
make log FOLLOW_LOGS=true
```

`make run` uses defaults from `Makefile.variables`, including `./src/scripts:/var/www`, `.env`, and container port `80`.

This image does not require default environment variables. Runtime environment values and secret references belong in `worker.yaml` or the target platform.

## Runtime

The runtime contract is defined by the Dockerfile and the configs copied into the image:

- `Dockerfile` pins the base Worker image and Ubuntu package versions.
- `etc/configs/nginx/` defines the NGINX server and PHP FastCGI integration.
- `etc/configs/php/` defines PHP-FPM process and pool behavior.
- `etc/configs/worker/services.yaml` declares Worker-managed services.

`/var/www` is both the declared volume and working directory. NGINX sends PHP requests to the PHP-FPM Unix socket configured during the image build.

## Development

Common commands:

```bash
make help
make build
make run HOST_PORT=8080
make exec
make log
make clean
```

Run all validation:

```bash
make test
```

Run only the container test suite against an already built image:

```bash
make run-all-tests
```

Run one test script:

```bash
make run-test TEST_SCRIPT=10_nginx_test.php
```

Current tests live in `src/tests/` and cover NGINX HTTP response, PHP runtime availability, PHP CLI execution, and write permissions under `/var/www`.

## Deployment

Deployment uses the host-native tool for the target environment. Mount application code at `/var/www` and publish container port `80` through the platform.

The GitHub release pipeline is declared in `.github/workflows/docker-ops.yml` and delegates Docker publishing to `udx/reusable-workflows`.

For dependency upgrades, include the changed base image/packages and the local verification result in the PR description.

## Worker Config

`worker.yaml` follows the base Worker config contract for runtime `config.env` values and `config.secrets` references. Deployment environment variables override values declared in `worker.yaml`.

See [docs/worker-config.md](docs/worker-config.md) for the local config reference.

References:

- https://github.com/udx/worker/blob/latest/docs/config.md
- https://github.com/udx/worker/blob/latest/docs/secrets.md
- https://github.com/udx/worker/blob/latest/docs/deployment.md

## Rabbit CI

Rabbit CI records this repository's GitHub delivery shape in [`.rabbit/repo.yaml`](.rabbit/repo.yaml). This image repo publishes the `worker-php` Docker image; it does not own tenant-specific Rabbit lifecycle manifests.

Run `rabbit.ci` after changing the repository's GitHub delivery configuration, including workflows, branch protection, Environments, or configured secret and variable names. Review and commit the generated resolution with the source change. See [`.rabbit/README.md`](.rabbit/README.md) for the resolution boundary and delivery entry points.

## Resources

- Docker Hub: https://hub.docker.com/r/usabilitydynamics/udx-worker-php
- Source: https://github.com/udx/worker-php
- Base runtime docs: https://github.com/udx/worker/tree/latest/docs

## License

MIT. See [LICENSE](LICENSE).
