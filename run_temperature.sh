#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Run temperature.py from this repository folder.
python3 "$SCRIPT_DIR/temperature.py"



