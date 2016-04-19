#!/bin/bash

set -e
set -x

SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )"

mkdir -p "${SCRIPT_DIR}/perf-files"
mkdir -p "${SCRIPT_DIR}/flamegraph-reports"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  source ${SCRIPT_DIR}/.env
fi

if [[ -z "${S3_BUCKET}" ]]; then
  echo "Please set the S3_BUCKET environment variable"
  exit 1
fi

aws s3 sync "${S3_BUCKET}" "${SCRIPT_DIR}/perf-files"

if ! [[ -f "${SCRIPT_DIR}/node_modules/.bin/stackvis" ]]; then
  npm install
fi

# if ! [[ -d "${SCRIPT_DIR}/FlameGraph" ]]; then
#   git clone git@github.com:brendangregg/FlameGraph.git "${SCRIPT_DIR}/FlameGraph"
# fi

for perf_file in ${SCRIPT_DIR}/perf-files/perf-script-*.txt; do
  base_name=${perf_file##*/}
  html_file="${SCRIPT_DIR}/flamegraph-reports/${base_name%.txt}.html"

  if [[ -f "${html_file}" ]]; then
    continue;
  fi

  egrep -v "( __libc_start| LazyCompile | v8::internal::| Builtin:| Stub:| LoadIC:|\[unknown\]| LoadPolymorphicIC:)" $perf_file |\
    sed 's/ LazyCompile:[*~]\?/ /' |\
    "${SCRIPT_DIR}/node_modules/.bin/stackvis" perf > $html_file

  # folded_file="${perf_file%.txt}.folded"
  # "${SCRIPT_DIR}/FlameGraph/stackcollapse-perf.pl" < $perf_file > $folded_file
  # "${SCRIPT_DIR}/FlameGraph/flamegraph.pl" < $folded_file > $svg_file
done
