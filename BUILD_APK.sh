#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
exec ./scripts/build-apk.sh
