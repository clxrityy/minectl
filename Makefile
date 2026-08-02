# ---------------------------------------
# Self-documenting help target.
# Parses ## comments on each target line.
# ---------------------------------------
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''

	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?##' Makefile | awk 'BEGIN {FS = "##"}; {printf "  %-20s %s\n", $$1, $$2}'

docker-test: ## Run tests in a Dockeer container
	@chmod	+x ./dev/*.sh
	@bash ./dev/test.sh