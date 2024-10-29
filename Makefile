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

# Wait for container to be ready (using Nginx PID as an indicator) with log inspection on timeout
wait-container-ready:
	@echo "Waiting for the container to be ready..."
	@counter=0; \
	while ! docker exec $(CONTAINER_NAME) test -f /var/run/nginx.pid; do \
		if [ $$counter -ge 30 ]; then \
			echo "Timeout: NGINX did not start"; \
			echo "Displaying NGINX logs for troubleshooting:"; \
			docker logs $(CONTAINER_NAME) || echo "No logs available"; \
			exit 1; \
		fi; \
		echo "Waiting for Nginx to be ready..."; \
		sleep 1; \
		counter=$$((counter + 1)); \
	done
	@echo "Container is ready."

# Run a specific test script (specified by TEST_SCRIPT)
run-test:
	@echo "Running test script $(TEST_SCRIPT) ..."
	@$(MAKE) run CMD="php $(CONTAINER_SRC_PATH)/tests/$(TEST_SCRIPT)"

# Run all tests in the tests directory with parallel execution and detailed logging
run-all-tests: clean
	@echo "Starting Docker container for test execution..."
	@docker run -d --name $(CONTAINER_NAME) -v $(CURDIR)/$(SRC_PATH):$(CONTAINER_SRC_PATH) -p $(HOST_PORT):$(CONTAINER_PORT) $(DOCKER_IMAGE)
	@$(MAKE) wait-container-ready
	@echo "Executing all test scripts with detailed logging..."
	@find $(SRC_PATH)/tests -name "*.php" | xargs -n 1 -P $(TEST_PARALLELISM) -I {} sh -c ' \
		test_file=$$(basename {}); \
		echo "Running $$test_file..."; \
		docker exec $(CONTAINER_NAME) php $(CONTAINER_SRC_PATH)/tests/$$test_file || echo "Test $$test_file failed"; \
	'
	@echo "All tests completed."

# Run the validation tests (build and run-all-tests)
test: build run-all-tests
	@echo "Validation tests completed."

# Development pipeline (build and test)
dev-pipeline: build test
	@echo "Development pipeline completed successfully."
