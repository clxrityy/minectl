help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = "##"}; {printf "  %-20s %s\n", $$1, $$2}'

colima-start: ## Start Colima for the test environment
	@colima start --cpu 4 --memory 8 --disk 40 --runtime docker
	@docker context use colima

colima-stop: ## Stop Colima
	@colima stop

docker-test: ## Run the full integration test harness
	@chmod	+x ./test/*.sh
	@bash ./test/test.sh

docker-test-colima: colima-start docker-test ## Start Colima and run tests

docker-clean: ## Remove test containers and volumes
	@cd test && if command -v docker-compose >/dev/null 2>&1; then docker-compose down -v; else docker compose down -v; fi

test: docker-clean docker-test ## Clean and run the full integration test harness