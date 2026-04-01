#!/bin/sh
set -o errexit -o nounset

CONTAINER_ENTRYPOINT="${CONTAINER_ENTRYPOINT:-/docker-entrypoint.sh}"

# Configurable prefix — defaults to "APP_"
VAR_PREFIX="${APP_ENV_PREFIX:-APP_}"
CONFIG_FILE="${CONFIG_FILE:-/usr/share/nginx/html/js/config.js}"

{
  printf 'window.__ENV__ = {\n'

  env | while read -r line; do
    key="${line%%=*}"
    value="${line#*=}"
    case "${key}" in
      "${VAR_PREFIX}"*)
        # Strip the prefix: APP_API_URL -> API_URL
        stripped="${key#"${VAR_PREFIX}"}"
        # Escape backslashes and double quotes
        escaped=$(printf '%s' "${value}" | sed 's/\\/\\\\/g; s/"/\\"/g')
        printf '  "%s": "%s",\n' "${stripped}" "${escaped}"
        ;;
    esac
  done

  printf '};\n'
} > "${CONFIG_FILE}"

if [ -x "${CONTAINER_ENTRYPOINT}" ]; then
  exec "${CONTAINER_ENTRYPOINT}" "${@}"
else
  exec "${@}"
fi
