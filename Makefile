# Include variables and help modules
include Makefile.variables
include Makefile.help

# Default target
.DEFAULT_GOAL := help

.PHONY: run deploy run-it clean build exec log test dev-pipeline run-test run-all-tests wait-container-ready

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

# Run Docker container for default tests (e.g., tests in /src/tests directory)
run: clean
	@echo "Running Docker container for testing..."
	@docker run -d --rm --name $(CONTAINER_NAME) \
		-v $(CURDIR)/$(SRC_PATH):$(CONTAINER_SRC_PATH) -p $(HOST_PORT):$(CONTAINER_PORT) \
		$(DOCKER_IMAGE)
	@$(MAKE) wait-container-ready
	@docker logs -f $(CONTAINER_NAME)

# Deploy application with the pulled Docker Hub image and user-provided app code
deploy: clean
	@echo "Deploying PHP application..."
	@docker run -d --rm --name $(CONTAINER_NAME) \
		-v $(CURDIR)/$(SRC_PATH):/var/www/html \
		-p $(HOST_PORT):80 \
		$(DOCKER_IMAGE)
	@echo "Application is accessible at http://localhost:$(HOST_PORT)"
	@$(MAKE) wait-container-ready

# Run Docker container in interactive mode
run-it:
	@$(MAKE) run INTERACTIVE=true CMD="/bin/sh"

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

# Wait for container to be ready (using HTTP readiness check on NGINX)
wait-container-ready:
	@echo "Waiting for the container to be ready..."
	@counter=0; \
	while ! curl -s -o /dev/null -w "%{http_code}" http://localhost:$(HOST_PORT) | grep -q "200"; do \
		if [ $$counter -ge 30 ]; then \
			echo "Timeout: Services did not start"; \
			echo "Displaying NGINX logs for troubleshooting:"; \
			docker logs $(CONTAINER_NAME) || echo "No logs available"; \
			exit 1; \
		fi; \
		echo "Waiting for services to be ready..."; \
		sleep 1; \
		counter=$$((counter + 1)); \
	done
	@echo "Container is ready."

# Run a specific test script (specified by TEST_SCRIPT)
run-test:
	@echo "Running test script $(TEST_SCRIPT) ..."
	@$(MAKE) run CMD="php $(CONTAINER_SRC_PATH)/tests/$(TEST_SCRIPT)"

# Run all tests in the tests directory
run-all-tests: clean
	@echo "Starting Docker container for test execution..."
	@docker run -d --name $(CONTAINER_NAME) -v $(CURDIR)/$(SRC_PATH):$(CONTAINER_SRC_PATH) -p $(HOST_PORT):$(CONTAINER_PORT) $(DOCKER_IMAGE)
	@$(MAKE) wait-container-ready
	@echo "Executing all test scripts..."
	@for test_script in $(SRC_PATH)/tests/*.php; do \
		echo "Running $$(basename $$test_script)..."; \
		docker exec $(CONTAINER_NAME) php $(CONTAINER_SRC_PATH)/tests/$$(basename $$test_script) || echo "Test $$(basename $$test_script) failed"; \
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
