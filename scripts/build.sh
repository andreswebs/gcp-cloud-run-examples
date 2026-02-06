#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

docker build --platform linux/amd64 --tag "${IMAGE_URI}" .
