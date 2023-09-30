#!/bin/bash -e

set -o pipefail

BAZEL="${BAZEL:-bazel}"
OUTPUT_DIR="${1:-_site}"

if  [[ -e "$OUTPUT_DIR" ]]; then
    echo "Path to build the website (${OUTPUT_DIR}) exists, removing contents"
    rm -rf "${OUTPUT_DIR:?}"/*
fi

mkdir -p "${OUTPUT_DIR}"

# TODO(phlax): think of a cleaner way to do this

bazel build //:dependency_versions
BUILD_DOCS_SHA="$(jq -r '.envoy.version' bazel-bin/dependency_shas.json)"
export BUILD_DOCS_SHA

BAZEL_BUILD_ARGS=()

if [[ -n "$CI" ]]; then
    BAZEL_BUILD_ARGS=(--config=ci)
fi

$BAZEL build "${BAZEL_BUILD_ARGS[@]}" //site

echo "Extracting website -> ${OUTPUT_DIR}"

$BAZEL run \
    @envoy//tools/zstd -- \
        --stdout \
        -d "${PWD}/bazel-bin/site/site_html.tar.zst" \
    | tar -x -C "${OUTPUT_DIR}"

if [[ -n "$CI" ]]; then
    $BAZEL shutdown || :
fi
