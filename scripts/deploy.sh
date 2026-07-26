#!/usr/bin/env bash
set -euo pipefail

cd "${DEPLOY_PATH:?DEPLOY_PATH is required}"

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

set_env_var() {
  local key="$1"
  local value="$2"
  if [ -z "$value" ]; then
    return 0
  fi
  if grep -q "^${key}=" .env; then
    grep -v "^${key}=" .env > .env.tmp || true
    mv .env.tmp .env
  fi
  printf '%s=%s\n' "$key" "$value" >> .env
}

set_env_var "GRAFANA_ADMIN_PASSWORD" "${GRAFANA_ADMIN_PASSWORD:-}"
set_env_var "GRAFANA_ADMIN_USER" "${GRAFANA_ADMIN_USER:-}"
set_env_var "GRAFANA_ROOT_URL" "${GRAFANA_ROOT_URL:-}"

if ! grep -q '^GRAFANA_ADMIN_PASSWORD=.\+' .env; then
  echo "GRAFANA_ADMIN_PASSWORD is empty — set the secret or edit .env on the server"
  exit 1
fi

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "Docker Compose is not installed on the server"
  exit 1
fi

echo "Using: ${COMPOSE[*]}"
"${COMPOSE[@]}" pull
# force-recreate so mounted configs (promtail/loki) are reloaded
"${COMPOSE[@]}" up -d --remove-orphans --force-recreate
"${COMPOSE[@]}" ps
