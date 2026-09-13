.PHONY: build test lint check run

build:
	go build ./...

test:
	go test ./...

lint:
	go vet ./...

# The gate CI treats as the bar.
check: build lint test

run:
	go run . -addr :8099
