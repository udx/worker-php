# Include variables and help modules
include Makefile.variables
include Makefile.help

# Default target
.DEFAULT_GOAL := help

.PHONY: run deploy run-it clean build exec log test dev-pipeline run-test run-all-tests wait-container-ready

# Build the Docker image
build:
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Building Docker image...$(COLOR_RESET)\n"
	@if [ "$(MULTIPLATFORM)" = "true" ]; then \
		printf "$(COLOR_BLUE)$(SYM_ARROW) Building for multiple platforms...$(COLOR_RESET)\n" && \
		docker buildx build --platform $(BUILD_PLATFORMS) -t $(DOCKER_IMAGE) .; \
	else \
		printf "$(COLOR_BLUE)$(SYM_ARROW) Building for local platform...$(COLOR_RESET)\n" && \
		docker build -t $(DOCKER_IMAGE) .; \
	fi && \
	printf "$(COLOR_GREEN)$(SYM_SUCCESS) Docker image build completed$(COLOR_RESET)\n" || \
	{ printf "$(COLOR_RED)$(SYM_ERROR) Docker build failed$(COLOR_RESET)\n"; exit 1; }

# Run Docker container (supports interactive mode)
run: clean
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Running Docker container...$(COLOR_RESET)\n"

	@if [ ! -f $(ENV_FILE) ]; then \
		printf "$(COLOR_YELLOW)$(SYM_WARNING) Creating environment file...$(COLOR_RESET)\n" && \
		touch $(ENV_FILE); \
	else \
		printf "$(COLOR_BLUE)$(SYM_ARROW) Using existing environment file$(COLOR_RESET)\n"; \
	fi

	@docker run $(if $(INTERACTIVE),-it,-d) --rm --name $(CONTAINER_NAME) \
		--env-file $(ENV_FILE) \
		-p $(HOST_PORT):$(CONTAINER_PORT) \
		$(foreach vol,$(VOLUMES),-v $(vol)) \
		$(DOCKER_IMAGE) && \
	printf "$(COLOR_GREEN)$(SYM_SUCCESS) Container started successfully$(COLOR_RESET)\n" || \
	{ printf "$(COLOR_RED)$(SYM_ERROR) Failed to start container$(COLOR_RESET)\n"; exit 1; }
	@$(MAKE) wait-container-ready
	

# Run Docker container in interactive mode
run-it:
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Starting interactive container...$(COLOR_RESET)\n"
	@$(MAKE) run INTERACTIVE=true CMD="/bin/bash"

# Execute a command in the running container
exec:
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Executing into container...$(COLOR_RESET)\n"
	@docker exec -it $(CONTAINER_NAME) /bin/bash || \
		{ printf "$(COLOR_RED)$(SYM_ERROR) Failed to execute into container$(COLOR_RESET)\n"; exit 1; }
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Successfully executed into container$(COLOR_RESET)\n"

# View the container logs
log:
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Fetching container logs...$(COLOR_RESET)\n"
	@if [ "$(FOLLOW_LOGS)" = "true" ]; then \
		docker logs -f $(CONTAINER_NAME) || \
			{ printf "$(COLOR_RED)$(SYM_ERROR) Failed to retrieve logs$(COLOR_RESET)\n"; exit 1; }; \
	else \
		docker logs $(CONTAINER_NAME) || \
			{ printf "$(COLOR_RED)$(SYM_ERROR) Failed to retrieve logs$(COLOR_RESET)\n"; exit 1; }; \
	fi
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Logs retrieved successfully$(COLOR_RESET)\n"

# Stop and remove the running container if it exists
clean:
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Cleaning up containers...$(COLOR_RESET)\n"
	@docker stop $(CONTAINER_NAME) 2>/dev/null || true
	@docker rm -f $(CONTAINER_NAME) 2>/dev/null || true
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Cleanup completed$(COLOR_RESET)\n"

# Wait for container to be ready (using HTTP readiness check on NGINX)
wait-container-ready:
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Waiting for container readiness...$(COLOR_RESET)\n"
	@counter=0; \
	while ! curl -s -o /dev/null -w "%{http_code}" http://localhost:$(HOST_PORT) | grep -q "200"; do \
		if [ $$counter -ge 30 ]; then \
			printf "$(COLOR_RED)$(SYM_ERROR) Timeout: Services did not start$(COLOR_RESET)\n"; \
			printf "$(COLOR_YELLOW)$(SYM_WARNING) Displaying NGINX logs for troubleshooting:$(COLOR_RESET)\n"; \
			docker logs $(CONTAINER_NAME) || printf "$(COLOR_RED)$(SYM_ERROR) No logs available$(COLOR_RESET)\n"; \
			exit 1; \
		fi; \
		printf "$(COLOR_BLUE)$(SYM_ARROW) Waiting for services to be ready...$(COLOR_RESET)\n"; \
		sleep 5; \
		counter=$$((counter + 1)); \
	done
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Container is ready$(COLOR_RESET)\n"

# Run a specific test script (specified by TEST_SCRIPT)
run-test: clean
	@if [ ! -f "$(SRC_PATH)/tests/$(TEST_SCRIPT)" ]; then \
		printf "$(COLOR_RED)$(SYM_ERROR) Test script not found: $(SRC_PATH)/tests/$(TEST_SCRIPT)$(COLOR_RESET)\n"; \
		exit 1; \
	fi
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Starting test container...$(COLOR_RESET)\n"
	@docker run -d --rm --name $(CONTAINER_NAME) -v $(CURDIR)/$(SRC_PATH):$(CONTAINER_SRC_PATH) -p $(HOST_PORT):$(CONTAINER_PORT) $(DOCKER_IMAGE) || \
		{ printf "$(COLOR_RED)$(SYM_ERROR) Failed to start test container$(COLOR_RESET)\n"; exit 1; }
	@$(MAKE) wait-container-ready || { $(MAKE) clean; exit 1; }
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Running $(TEST_SCRIPT)...$(COLOR_RESET)\n"
	@docker exec $(CONTAINER_NAME) php $(CONTAINER_SRC_PATH)/tests/$(TEST_SCRIPT) && \
	printf "$(COLOR_GREEN)$(SYM_SUCCESS) Test $(TEST_SCRIPT) passed$(COLOR_RESET)\n" || \
	{ printf "$(COLOR_RED)$(SYM_ERROR) Test $(TEST_SCRIPT) failed$(COLOR_RESET)\n"; $(MAKE) clean; exit 1; }
	@$(MAKE) clean

# Run all tests in the tests directory
run-all-tests: clean
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Starting test container...$(COLOR_RESET)\n"
	@docker run -d --name $(CONTAINER_NAME) -v $(CURDIR)/$(SRC_PATH):$(CONTAINER_SRC_PATH) -p $(HOST_PORT):$(CONTAINER_PORT) $(DOCKER_IMAGE)
	@$(MAKE) wait-container-ready
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Executing all test scripts...$(COLOR_RESET)\n"
	@for test_script in $(SRC_PATH)/tests/*.php; do \
		printf "$(COLOR_BLUE)$(SYM_ARROW) Running $$(basename $$test_script)...$(COLOR_RESET)\n"; \
		docker exec $(CONTAINER_NAME) php $(CONTAINER_SRC_PATH)/tests/$$(basename $$test_script) && \
		printf "$(COLOR_GREEN)$(SYM_SUCCESS) Test $$(basename $$test_script) passed$(COLOR_RESET)\n" || \
		{ printf "$(COLOR_RED)$(SYM_ERROR) Test $$(basename $$test_script) failed$(COLOR_RESET)\n"; exit 1; }; \
	done
	@$(MAKE) clean
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) All tests completed successfully$(COLOR_RESET)\n"

# Run the validation tests (build and run-all-tests)
test: build run-all-tests
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Validation tests completed successfully$(COLOR_RESET)\n"

# Development pipeline (build and test)
dev-pipeline: build test
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Development pipeline completed successfully$(COLOR_RESET)\n"
