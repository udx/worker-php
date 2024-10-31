# UDX Worker PHP

A versatile Docker image for running PHP applications with NGINX and PHP-FPM, providing a ready-to-use environment to deploy and serve your PHP projects.

## Overview

The image is designed as a general-purpose base for PHP application development and deployment. It includes essential configurations for NGINX and PHP-FPM to streamline your setup, making it easy to get started with popular frameworks and custom applications alike.

### Based on udx-worker

Built on `udx-worker`, this image benefits from secure, resource-efficient configurations and best practices, providing a reliable foundation for PHP applications.

## Development

### Prerequisites

- Ensure `Docker` is installed and running on your system.

### Quick Start

This image serves as a base for your PHP applications. The `src/tests/` directory includes sample tests for verifying PHP and NGINX functionality, but it does not contain application code by default.

### Running Built-In Tests

1. Clone this repository:

```
git clone https://github.com/udx/udx-worker-php.git
cd udx-worker-php
```

2. Build the Docker image:

```
make build
```

3. Run Tests to verify functionality:

```
make run-all-tests
```

You can add additional tests in the `src/tests/` directory as needed.

## Deployment

### Deploying Using the Pre-Built Image

If you want to use the pre-built image directly from Docker Hub without cloning the repository:

1. Pull the Image:

```
docker pull usabilitydynamics/udx-worker-php:latest
```

2. Run the container with your application code:

```
docker run -d --name my-php-app \
  -v $(pwd)/my-php-app:/var/www/html \
  -p 80:80 \
  usabilitydynamics/udx-worker-php:latest
```

This serves your application at http://localhost.

3. Stop and remove the container when done:

```
docker rm -f my-php-app
```

### Deploying Using a Locally Built Image (Makefile Approach)

If you’ve cloned this repository and built the image locally, you can use the provided Makefile targets:

1. Build the Image (if not already built):

```
make build
```

2. Run the Container:

```
make run
```

By default, this command runs the container with the code located in the `src/` directory of this repository.

3. Deploy Application Code. If your PHP application code is located in a different directory or repository, use the deploy target to mount it as a volume:

```
APP_PATH=/path/to/your-php-app make deploy
```

- Replace `/path/to/your-php-app` with the path to your PHP application directory.
- This command will mount your specified application directory into the container’s `/var/www/html` directory, allowing you to run your custom application directly.

## Configuration

You can configure build and runtime variables in `Makefile.variables`:

- PHP and NGINX versions. _(Only PHP8.3 supported for now)_
- Port mappings
- Source paths

Adjust these variables to suit your environment or specific deployment requirements.

## Makefile Commands Helper

Use make to view all available commands:

```
make help
```

These commands offer options for building, running, and testing your application seamlessly.
