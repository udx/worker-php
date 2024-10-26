# UDX Worker PHP Repository

This repository contains a containerized PHP application built on the `udx-worker` base image.

## Development

### Prerequisites

- Docker installed.
- PHP scripts should be placed in the `src/scripts/` directory (these scripts are not part of this repository and should be added by the user).

### Key Commands

- **Build the Docker Image**: `make build`
- **Run the Container**: `make run`
- **Run in Interactive Mode**: `make run-it`
- **Exec into the Container**: `make exec`
- **View Logs**: `make log`

## Deployment

1. **Build the Image**: `make build`
2. **Push to Registry**: Tag and push the image to your container registry.
3. **Deploy Your Own App**:
   - Place your PHP scripts in the `src/scripts/` directory.
   - Build and push the image to your registry.
   - Deploy using `docker run`, specifying your custom command if needed, e.g.,
     ```sh
     docker run -d --name udx-worker-php -p 8080:8080 your-registry/udx-worker-php:latest php /usr/src/app/scripts/your-script.php
     ```

## Cleanup

- **Remove Container**: `make clean`
