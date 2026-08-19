# Review Guidelines - worker-php

PHP-FPM + nginx runtime image, `FROM usabilitydynamics/udx-worker` (pinned tag), runs as UID 500. Direct parent of worker-site, therefore of every WordPress tenant.

## Critical Areas (extra scrutiny)

- `bin/start-nginx.sh`, `bin/start-php-fpm.sh`: service startup; must stay fail-fast and UID-500-safe.
- `etc/configs/php/php-fpm.conf` and `etc/configs/php/www.conf`: pool sizing here is consumed by tenant ConfigMaps downstream (see worker-site docs/phpfpm.md). Changing pool defaults changes tenant capacity; require explicit intent and downstream notes.
- `etc/configs/nginx/{nginx.conf,default.conf,snippets/fastcgi-php.conf}`: serving behavior for all PHP tenants; review for exposure (status endpoints, dotfiles, buffer/timeout changes).
- `etc/configs/worker/services.yaml`: supervision contract.
- Dockerfile: pinned `PHP_PACKAGE_VERSION` / `NGINX_VERSION` ARGs stay pinned; `USER` and ownership changes carry the usual UID 500 downstream risk - require worker-site verification.

## Release Model

- Merge to `latest` cuts a Minor release IF the diff touches `bin/**`, `Dockerfile`, `etc/**`, `ci/**`, `src/**`, or `LICENSE`. GitVersion versioning, no changelog: the PR description must state whether worker-site needs a FROM-pin bump.

## Conventions to Enforce

- shellcheck, hadolint, yamllint green; `make test` passes.
- Base-image discipline: new packages/extensions need a downstream consumer, not speculation.
