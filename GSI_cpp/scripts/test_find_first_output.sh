#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
make GSI.exe

log_file="${TMPDIR:-/tmp}/gsi_find_first_test.log"
./GSI.exe data/text_data.g data/text_query.g "${TMPDIR:-/tmp}/gsi_find_first_test.out" 0 --find-first >"${log_file}" 2>&1

grep -q '^find_first: 1$' "${log_file}"
grep -q '^found_first: [01]$' "${log_file}"
grep -Eq '^fms: [0-9]+$' "${log_file}"
