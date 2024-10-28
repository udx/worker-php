# Include variables and help modules
include Makefile.variables
include Makefile.help

# Default target
.DEFAULT_GOAL := help

.PHONY: run run-it clean build exec log test dev-pipeline run-with-volume run-test run-all-tests wait-container-ready

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
		-v $(CURDIR)/$(SRC_PATH):$(CONTAINER_SRC_PATH) -p $(HOST_PORT):$(CONTAINER_PORT) \
		$(DOCKER_IMAGE) $(CMD)
	$(if $(filter false,$(INTERACTIVE)),docker logs -f $(CONTAINER_NAME);)

# Run Docker container in interactive mode
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
	@docker logs $(CONTAINER_NAME) || echo "No running container to log."

# Stop and remove the running container if it exists
clean:
	@echo "Stopping and removing Docker container if it exists..."
	@docker rm -f $(CONTAINER_NAME) || true

# Wait for container to be ready (using Nginx PID as indicator)
wait-container-ready:
	@echo "Waiting for the container to be ready..."
	@timeout 30s bash -c ' \
	while ! docker exec $(CONTAINER_NAME) test -f /var/run/nginx.pid; do \
		echo "Waiting for Nginx to be ready..."; \
		sleep 1; \
	done' || { echo "Timeout: NGINX did not start"; exit 1; }
	@echo "Container is ready."

# Run specific test script
run-test:
	@$(MAKE) run CMD="php $(TEST_SCRIPT_PATH)"

# Run all tests in the tests directory in a single container instance
run-all-tests:
	@echo "Stopping and removing Docker container if it exists..."
	@docker rm -f $(CONTAINER_NAME) || true
	@echo "Running Docker container..."
	@docker run -d --name $(CONTAINER_NAME) -v $(CURDIR)/$(SRC_PATH):$(CONTAINER_SRC_PATH) -p $(HOST_PORT):$(CONTAINER_PORT) $(DOCKER_IMAGE)
	@$(MAKE) wait-container-ready
	@echo "Executing all test scripts..."
	@for test_script in $(CURDIR)/$(SRC_PATH)/tests/*.php; do \
		docker exec $(CONTAINER_NAME) php $(CONTAINER_SRC_PATH)/tests/$$(basename $$test_script); \
	done
	@echo "Stopping and removing Docker container..."
	@docker rm -f $(CONTAINER_NAME)
	@echo "All tests completed."

# Run the validation tests (build and run-all-tests)
test: build run-all-tests
	@echo "Validation tests completed."

# Development pipeline (build and test)
dev-pipeline: build test
	@echo "Development pipeline completed successfully."
