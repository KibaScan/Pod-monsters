#!/bin/bash

# Ensure we are running from the project root
if [ ! -f "Package.swift" ]; then
  echo "Error: check_numbers.sh must be run from the project root directory."
  exit 1
fi

echo "Running Swift test suite..."
swift test > test_out.log 2>&1
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -ne 0 ]; then
  echo "Error: swift test execution failed."
  cat test_out.log
  rm -f test_out.log
  exit $TEST_EXIT_CODE
fi

TEST_LINE=$(grep -E "Executed [0-9]+ tests, with [0-9]+ failures" test_out.log | tail -n 1)
rm -f test_out.log

if [ -z "$TEST_LINE" ]; then
  echo "Error: Could not parse XCTest summary from swift test output."
  exit 1
fi

TESTS_RUN=$(echo "$TEST_LINE" | grep -oE "[0-9]+ tests" | head -n 1 | awk '{print $1}')
TESTS_FAILED=$(echo "$TEST_LINE" | grep -oE "[0-9]+ failures" | head -n 1 | awk '{print $1}')

if [ -z "$TESTS_RUN" ] || [ -z "$TESTS_FAILED" ]; then
  echo "Error: Failed to extract test counts from XCTest summary."
  exit 1
fi

# Count decisions in docs/DECISIONS.md
if [ -f "docs/DECISIONS.md" ]; then
  DECISIONS_COUNT=$(grep -c "^## D-" docs/DECISIONS.md)
else
  DECISIONS_COUNT=0
fi

# Parse documented stats from docs/status/CURRENT.md
if [ -f "docs/status/CURRENT.md" ]; then
  DOC_TESTS=$(grep -E "\*\*Total Tests\*\*:" docs/status/CURRENT.md | grep -oE "[0-9]+" | head -n 1)
  DOC_FAILED=$(grep -E "\*\*Failing Tests\*\*:" docs/status/CURRENT.md | grep -oE "[0-9]+" | head -n 1)
  DOC_DECISIONS=$(grep -E "\*\*Architectural Decisions\*\*:" docs/status/CURRENT.md | grep -oE "[0-9]+" | head -n 1)
else
  echo "Error: docs/status/CURRENT.md not found."
  exit 1
fi

# Perform Drift Comparison
DRIFT_DETECTED=0

echo "=== Pod Monsters Freshness Check ==="
echo "Test Cases: Reality = $TESTS_RUN | Documented = $DOC_TESTS"
echo "Test Failures: Reality = $TESTS_FAILED | Documented = $DOC_FAILED"
echo "Decisions: Reality = $DECISIONS_COUNT | Documented = $DOC_DECISIONS"

if [ "$TESTS_RUN" -ne "$DOC_TESTS" ]; then
  echo "WARNING: Test count drift detected!"
  DRIFT_DETECTED=1
fi

if [ "$TESTS_FAILED" -ne "$DOC_FAILED" ]; then
  echo "WARNING: Test failure count drift detected!"
  DRIFT_DETECTED=1
fi

if [ "$DECISIONS_COUNT" -ne "$DOC_DECISIONS" ]; then
  echo "WARNING: Decision count drift detected!"
  DRIFT_DETECTED=1
fi

if [ "$DRIFT_DETECTED" -eq 1 ]; then
  echo "FAIL: Freshness drift detected. Please update docs/status/CURRENT.md."
  exit 1
else
  echo "SUCCESS: No freshness drift detected. All numbers match!"
  exit 0
fi
