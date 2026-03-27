#!/usr/bin/env bash
# Run full test coverage, write filtered lcov, print both aggregates.
# Optional: fail if filtered or full coverage is below a threshold (CI gate).
#
# Usage:
#   ./tool/coverage.sh
#   ./tool/coverage.sh --min-filtered-percent=80
#   ./tool/coverage.sh --min-full-percent=80
#   ./tool/coverage.sh --min-full-percent=80 --min-filtered-percent=80

set -euo pipefail
cd "$(dirname "$0")/.."

MIN=""
MIN_FULL=""
for arg in "$@"; do
  case "$arg" in
    --min-filtered-percent=*)
      MIN="${arg#--min-filtered-percent=}"
      ;;
    --min-full-percent=*)
      MIN_FULL="${arg#--min-full-percent=}"
      ;;
  esac
done

flutter test --coverage

echo ""
echo "=== Full lcov.info ==="
FULL_LH="$(awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{printf "%d", lh}' coverage/lcov.info)"
FULL_LF="$(awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{printf "%d", lf}' coverage/lcov.info)"
awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{printf "Lines hit: %d / %d (%.2f%%)\n", lh, lf, (lf>0?100*lh/lf:0)}' coverage/lcov.info

if [[ -n "$MIN_FULL" ]]; then
  python3 - "$FULL_LH" "$FULL_LF" "$MIN_FULL" <<'PY' || exit 1
import sys
lh, lf, m = int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3])
pct = 100.0 * lh / lf if lf else 0.0
if pct + 1e-9 < m:
    print(
        f"FAILED: full lcov coverage {pct:.2f}% is below --min-full-percent={m}",
        file=sys.stderr,
    )
    sys.exit(1)
PY
fi

echo ""
if [[ -n "$MIN" ]]; then
  dart run tool/coverage_filtered.dart --min-percent="$MIN"
else
  dart run tool/coverage_filtered.dart
fi
