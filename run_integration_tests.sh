#!/bin/bash

# Make sure Prism is installed
if ! command -v prism &> /dev/null; then
    echo "Prism is not installed. Please install it first:"
    echo "npm install -g @stoplight/prism-cli"
    exit 1
fi

# Kill any existing Prism processes
echo "Cleaning up any existing Prism processes..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    lsof -ti:4011 | xargs kill -9 2>/dev/null || true
else
    # Linux
    fuser -k 4011/tcp 2>/dev/null || true
fi

# Start Prism server
echo "Starting Prism mock server..."
prism mock https://developer.spotify.com/reference/web-api/open-api-schema.yaml --port 4011 &
PRISM_PID=$!

# Wait for server to start
sleep 2

# Run integration tests
echo "Running integration tests..."
flutter test integration_test

# Kill Prism server
echo "Cleaning up..."
kill -9 $PRISM_PID 2>/dev/null || true

# Additional cleanup
if [[ "$OSTYPE" == "darwin"* ]]; then
    lsof -ti:4011 | xargs kill -9 2>/dev/null || true
else
    fuser -k 4011/tcp 2>/dev/null || true
fi

echo "Tests completed"
