#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="/workspace/rusin/src:${PYTHONPATH:-}"
python3 -m rusin.train "$@"