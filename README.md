# UDX Worker PHP

A versatile Docker image for running PHP applications with NGINX and PHP-FPM, providing a ready-to-use environment to deploy and serve your PHP projects.

## Development

### Prerequisites

- **Docker** installed

### Using the Image

This image is designed to serve as a base for developing and deploying PHP applications. It’s simple to adapt:

- No application scripts are included by default. The `src/tests/` directory includes sample tests for PHP and NGINX functionality.
- Add your own scripts or extend the image for specific applications, such as WordPress or Laravel.

### Commands

Use `make` to view all available commands and configurable variables.

## Deployment

1. Build image `make build`
2. Run Your App `make run`

## Configuration

You can configure build and runtime variables in Makefile.variables for easy adjustments.
