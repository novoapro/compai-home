.PHONY: generate dev prod test test-swift test-web web-dev web-install clean kill help

XCODEBUILD = xcodebuild -scheme HomeKitMCP -destination 'platform=macOS,variant=Mac Catalyst'
DERIVED_DATA = $(HOME)/Library/Developer/Xcode/DerivedData
APP_PATH = $(shell find $(DERIVED_DATA) -name "HomeKitMCP.app" -path "*-maccatalyst*" 2>/dev/null | head -1)

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

generate: ## Regenerate Xcode project from project.yml
	xcodegen generate

dev: kill generate ## Build and run in Dev config
	$(XCODEBUILD) -configuration 'Dev Debug' build
	@echo "Launching HomeKitMCP (Dev)..."
	@open "$$(find $(DERIVED_DATA) -name 'HomeKitMCP.app' -path '*Dev Debug-maccatalyst*' 2>/dev/null | head -1)"

prod: kill generate ## Build and run in Prod config
	$(XCODEBUILD) -configuration 'Prod Debug' build
	@echo "Launching HomeKitMCP (Prod)..."
	@open "$$(find $(DERIVED_DATA) -name 'HomeKitMCP.app' -path '*Prod Debug-maccatalyst*' 2>/dev/null | head -1)"

test: test-swift test-web ## Run all tests

test-swift: generate ## Run Swift unit tests
	$(XCODEBUILD) -configuration 'Dev Debug' test

test-web: ## Run web app tests
	cd log-viewer-web && npm test

web-dev: ## Start web app dev server
	cd log-viewer-web && npm run dev

web-install: ## Install web app dependencies
	cd log-viewer-web && npm ci

clean: ## Clean build artifacts
	$(XCODEBUILD) clean || true
	rm -rf log-viewer-web/dist log-viewer-web/node_modules/.vite

kill: ## Kill running HomeKitMCP process
	pkill -9 -f HomeKitMCP || true
