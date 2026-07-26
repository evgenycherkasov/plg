# PLG — Promtail + Loki + Grafana

Стек для сбора Docker-логов и визуализации в экосистеме Grafana.

| Сервис   | Роль                                      | Порт по умолчанию |
|----------|-------------------------------------------|-------------------|
| Promtail | сбор логов контейнеров через Docker socket | —                 |
| Loki     | хранение и запросы логов                  | 3100              |
| Grafana  | UI и дашборды                             | 3000              |

## Быстрый старт (локально)

```bash
cp .env.example .env
# задайте GRAFANA_ADMIN_PASSWORD в .env

docker compose up -d
```

Откройте Grafana: http://localhost:3000  
Логин/пароль — из `.env` (`GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD`).

Готовый дашборд: **PLG → Docker Logs**.

### Примеры LogQL

```logql
{container="my-app"}
{compose_project="shop"} |= "error"
{container=~".+"} |~ "(?i)exception|panic"
```

## Требования на сервере

- Docker Engine + Docker Compose (plugin `docker compose` или `docker-compose`)
- SSH с **PasswordAuthentication yes** (деплой идёт по логину/паролю, без ключей)
- Пользователь деплоя должен уметь запускать Docker (`docker` в PATH; обычно член группы `docker` или root)

## GitHub Actions: деплой по SSH (логин + пароль)

Workflow: [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)

Срабатывает на push в `main`/`master` и вручную (`workflow_dispatch`).

### Secrets репозитория

Settings → Secrets and variables → Actions:

| Secret | Обязательный | Описание |
|--------|--------------|----------|
| `SSH_HOST` | да | IP или hostname сервера |
| `SSH_USERNAME` | да | SSH-пользователь |
| `SSH_PASSWORD` | да | SSH-пароль |
| `DEPLOY_PATH` | да | Каталог на сервере, например `/opt/plg` |
| `SSH_PORT` | нет | Порт SSH (по умолчанию `22`) |
| `GRAFANA_ADMIN_PASSWORD` | рекомендуется | Пароль админа Grafana (пишется в `.env` на сервере) |
| `GRAFANA_ADMIN_USER` | нет | Логин Grafana (по умолчанию `admin`) |
| `GRAFANA_ROOT_URL` | нет | Публичный URL Grafana, например `https://logs.example.com` |

Деплой:

1. Создаёт `DEPLOY_PATH` на сервере  
2. Копирует файлы стека по SCP (аутентификация паролем)  
3. Обновляет `.env` при наличии Grafana-секретов  
4. Выполняет `docker compose pull && docker compose up -d`

### Важно про SSH пароль

На сервере в `/etc/ssh/sshd_config` должно быть:

```
PasswordAuthentication yes
```

После изменения: `sudo systemctl restart sshd` (или `ssh`).

## Структура

```
.
├── docker-compose.yml
├── .env.example
├── loki/loki-config.yml
├── promtail/promtail-config.yml
├── grafana/provisioning/
│   ├── datasources/loki.yml
│   └── dashboards/
└── .github/workflows/deploy.yml
```

## Retention

В `loki/loki-config.yml` срок хранения логов — **1 час** (`retention_period: 1h`). Меняйте при необходимости.
