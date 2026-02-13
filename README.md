<img src="assets/logo.svg" alt="UDX Worker PHP">

# UDX Worker PHP

[![Docker Pulls](https://img.shields.io/docker/pulls/usabilitydynamics/udx-worker-php.svg)](https://hub.docker.com/r/usabilitydynamics/udx-worker-php)
[![License](https://img.shields.io/github/license/udx/worker-php.svg)](LICENSE)

PHP runtime image built on UDX Worker with NGINX + PHP-FPM preconfigured.

[Quick Start](#quick-start) • [Usage](#usage) • [Development](#development) • [Resources](#resources)

## Overview

`udx-worker-php` extends [`udx/worker`](https://github.com/udx/worker) and keeps the same worker runtime model while adding:

- NGINX configured for `/var/www`
- PHP-FPM (`8.4`) with socket-based NGINX integration
- Worker service definitions that autostart both `php-fpm` and `nginx`

This image is intended as a base runtime for PHP applications and PHP-focused automation workloads.

## Quick Start

Requirements: Docker (and Make if you want local dev commands).

### Run from Docker Hub

```bash
docker run -d \
  --name my-php-app \
  -p 80:80 \
  -v "$(pwd)/my-php-app:/var/www" \
  usabilitydynamics/udx-worker-php:latest
```

Then open `http://localhost` (or your mapped host port).

### Local Development Workflow

```bash
git clone https://github.com/udx/worker-php.git
cd worker-php

make build
make run
make log FOLLOW_LOGS=true
```

`make run` uses these defaults from `Makefile.variables`:

- volume: `./src/scripts:/var/www`
- host/container port: `80:80`
- env file: `.env`

## Usage

### Mount your own app code

```bash
make run VOLUMES="$(pwd)/path-to-app:/var/www" HOST_PORT=8080
```

### Run interactively

```bash
make run-it
```

### Execute into the running container

```bash
make exec
```

### Deploy with Worker CLI config

This repo includes a sample `deploy.yml` for [`@udx/worker-deployment`](https://www.npmjs.com/package/@udx/worker-deployment).

```bash
npm install -g @udx/worker-deployment
worker run
```

## Testing

Run all built-in tests:

```bash
make run-all-tests
```

Run full validation (build + tests):

```bash
make test
```

Run a specific test script:

```bash
make run-test TEST_SCRIPT=10_nginx_test.php
```

Current tests live in `src/tests/` and cover:

- NGINX HTTP response
- PHP runtime availability
- CLI execution
- write permissions under `/var/www`

## Configuration

Primary defaults are in `Makefile.variables`:

- `DOCKER_IMAGE`
- `CONTAINER_NAME`
- `HOST_PORT` / `CONTAINER_PORT`
- `VOLUMES`
- `PHP_VERSION`

Container/runtime config files:

- `etc/configs/nginx/default.conf`
- `etc/configs/php/php-fpm.conf`
- `etc/configs/php/www.conf`
- `etc/configs/worker/services.yaml`

## Development

Useful commands:

```bash
make help
make build
make run
make log
make clean
make test
```

## Resources

- Docker Hub: https://hub.docker.com/r/usabilitydynamics/udx-worker-php
- Source: https://github.com/udx/worker-php
- Base runtime docs: https://github.com/udx/worker/tree/latest/docs
- Deployment config docs: https://github.com/udx/worker-deployment/blob/latest/docs/deploy-config.md

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your branch
5. Open a pull request

Include relevant tests and documentation updates with your changes.

## License

MIT. See [`LICENSE`](LICENSE).
