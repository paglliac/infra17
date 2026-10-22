# infra

Сервисы на VPS `gang.su` (Debian 13): каждый живёт на своём поддомене `<имя>.gang.su` за Caddy с HTTPS. Сам хост и хаб SecondBrain на `gang.su` разворачивает `deploy/` в репо SecondBrain (`bootstrap.yml` — админ `kir`, ufw, swap; `site.yml` — хаб и Caddy). Здесь — всё остальное.

## Как устроено

- `group_vars/all/services.yml` — список сервисов: репо, порт, поддомен, рантайм, команда запуска, секреты. Поля описаны в начале файла. `ports_taken` — порты, занятые не отсюда (SecondBrain, 3141); два сервиса на одном порту плейбук не пропустит.
- `site.yml`:
  - роль `caddy` — гарантирует строку `import /etc/caddy/sites/*.caddy` в `/etc/caddy/Caddyfile` (шаблон SecondBrain содержит ту же строку, так что его `make deploy` её не стирает);
  - `node` (Node.js из nodejs.org в `/opt/node`, мажорная версия — `node_major`) и `python` — ставятся, если они нужны выбранным сервисам; Node — и для сервиса на Python со сборкой (`build`);
  - `claude` — Claude Code CLI (`/usr/bin/claude`, apt-пакет `claude-code`) для сервисов с `claude: true`; репозиторий Anthropic и версию держит деплой SecondBrain, здесь пакет только проверяется;
  - `service` — для каждого сервиса: системный пользователь `<имя>`, `/srv/<имя>/{app,data,.env}`, свой deploy key для GitHub, `git` checkout, зависимости, сборка (`build`, после каждого нового коммита), systemd-юнит `<имя>` с `environment`, `/etc/caddy/sites/<имя>.caddy`, проверка, что сервис отвечает.
- `.env` сервиса создаётся один раз и правится только построчно: секреты из `secrets` генерируются при первом запуске, ключи из `env_keys` берутся из локального `.env` (путь — в `inventory.local.yml`) или задаются `make env`.

## Команды

```sh
make deploy                 # все сервисы
make deploy S=budget        # один (go — игра в го, go.gang.su)
make app S=budget           # только код: git pull, зависимости, рестарт
make env S=budget K=KEY     # задать ключ в .env сервиса (значение спросит)
make data S=budget FROM=~/budget17/data   # SQLite-базы из локальной папки поверх серверных
```

## Новый сервис

1. Запись в `services.yml` со свободным портом и поддоменом. DNS не нужен: `*.gang.su` уже смотрит на сервер.
2. `make deploy S=<имя>`. Первый прогон остановится и напечатает deploy key — добавить его в репо (Settings → Deploy keys, только чтение) и запустить ещё раз. GitHub не даёт один ключ двум репо, поэтому у каждого сервиса свой.

## С нуля

На управляющей машине: `ansible` (ansible-core ≥ 2.15), коллекции `ansible.posix` и `community.general`, ssh-ключ админа сервера. `cp inventory.example.yml inventory.local.yml` и заполнить.
