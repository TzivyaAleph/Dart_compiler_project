#!/usr/bin/env bash
set -euo pipefail

# Resolve Dart dependencies for every project that defines a pubspec.yaml.
# Safe to run repeatedly: `dart pub get` is idempotent.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

dart --version

for pubspec in */pubspec.yaml; do
  project_dir="$(dirname "$pubspec")"
  echo "==> dart pub get in ${project_dir}"
  (cd "$project_dir" && dart pub get)
done

echo "All Dart projects resolved."
