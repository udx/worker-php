# Include variables and help modules
include Makefile.variables
include Makefile.help

# Default target
.DEFAULT_GOAL := help

.PHONY: run run-it clean build exec log test dev-pipeline run-with-volume run-test

# Build the Docker image
build:
	@echo "Building Docker image..."
	@if [ "$(MULTIPLATFORM)" = "true" ]; then \
		echo "Building Docker image for multiple platforms..."; \
		docker buildx build --platform $(BUILD_PLATFORMS) -t $(DOCKER_IMAGE) .; \
	else \
		echo "Building Docker image for the local platform..."; \
		docker build -t $(DOCKER_IMAGE) .; \
	fi
	@echo "Docker image build completed."

# Run Docker container with optional command
run: clean
	@echo "Running Docker container..."
	@docker run $(if $(INTERACTIVE),-it,-d) --rm --name $(CONTAINER_NAME) \
		-v $(CURDIR)/src:/var/www/html -p $(HOST_PORT):$(CONTAINER_PORT) \
		$(DOCKER_IMAGE) $(CMD)
	$(if $(filter false,$(INTERACTIVE)),docker logs -f $(CONTAINER_NAME);)

# Run Docker container in interactive mode (calls run with INTERACTIVE=true)
run-it:
	@$(MAKE) run INTERACTIVE=true CMD="/bin/sh"

# Run Docker container with volume and port mapping (calls run without CMD)
run-with-volume:
	@$(MAKE) run

# Execute a command in the running container
exec:
	@echo "Executing into Docker container..."
	@docker exec -it $(CONTAINER_NAME) /bin/sh

# View the container logs
log:
	@echo "Viewing Docker container logs..."
	@docker logs $(CONTAINER_NAME)

# Stop and remove the running container if it exists
clean:
	@echo "Stopping and removing Docker container if it exists..."
	@docker rm -f $(CONTAINER_NAME) || true

# Run the container and execute a test command (reuses run target)
run-test:
	@$(MAKE) run CMD="php $(TEST_SCRIPT_PATH)"

# Run the validation tests (build and run-test)
test: build run-test
	@echo "Validation tests completed."

# Development pipeline (build and test)
dev-pipeline: build test
	@echo "Development pipeline completed successfully."
