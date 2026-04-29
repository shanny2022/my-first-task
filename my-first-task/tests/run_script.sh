#!/bin/bash
set -e
cd "/app/pydantic-assessment"

if [ $# -ge 1 ] && [ -n "$1" ]; then
  IFS=',' read -r -a TEST_FILES <<< "$1"
  python3 -m pytest -xvs "${TEST_FILES[@]}" 2>&1
else
  python3 -m pytest -xvs 2>&1
fi
