# UDX Worker PHP Repository

A flexible Docker image for running PHP applications.It includes NGINX and PHP-FPM, providing a ready-to-use environment to deploy and serve your PHP projects.

## Development

### Prerequisites

- **Docker** installed

### Using the Image

This image can be used as a base for developing and deploying your PHP applications:

- The `src/scripts/` directory contains a simple test script to verify PHP functionality.
- No application scripts are included by default.
- You can add your own scripts or create a child Docker image for specific use cases, such as WordPress or Laravel.

### Commands

Run `make` to see all available commands and variables.

## Deployment

1. **Build Image**: `make build`
2. **Push to Registry**: Tag and push the image to your container registry.
3. **Run Your App**:
   - Run the following command to deploy your PHP application:
     ```sh
     docker run -d -p 8080:80 -v /path/to/your/php/app:/var/www/html --name your-app-container udx-worker-php:latest
     ```
   - Replace `/path/to/your/php/app` with the path to your PHP application code.

## Configuration

Configurations are in `Makefile.variables` for easy editing.

## Notes

Based on the `udx-worker` base image, which provides a standardized environment with essential tools for running various applications, ensuring consistency and ease of deployment. Learn more about it [here](https://udx.io/products/udx-worker).
