#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BIN="${TMPDIR:-/tmp}/nourish-matcher-evaluation"

swiftc \
  -parse-as-library \
  "$ROOT/Nourish/Utilities/QuantityParser.swift" \
  "$ROOT/Nourish/Data/FoodNutritionEntry.swift" \
  "$ROOT/Nourish/Data/LocalFoodDatabase.swift" \
  "$ROOT/Nourish/Utilities/FoodMatcher.swift" \
  "$ROOT/Nourish/Services/FoodParsingService.swift" \
  "$ROOT/Nourish/Services/LocalFoodDatabaseParsingService.swift" \
  "$ROOT/Tools/MatcherEvaluation/main.swift" \
  -o "$BIN"

"$BIN" "$ROOT/Tools/MatcherEvaluation/evaluation_cases.json"
