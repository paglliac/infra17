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
make vpn                    # VPN для своих устройств, профили в vpn-profiles/
make direct                 # сайты из direct в services.yml — с адреса сервера, мимо awg0
```

## Новый сервис

1. Запись в `services.yml` со свободным портом и поддоменом. DNS не нужен: `*.gang.su` уже смотрит на сервер.
2. `make deploy S=<имя>`. Первый прогон остановится и напечатает deploy key — добавить его в репо (Settings → Deploy keys, только чтение) и запустить ещё раз. GitHub не даёт один ключ двум репо, поэтому у каждого сервиса свой.

## VPN

Свои устройства подключаются к `gang.su`, а их трафик выходит дальше через `awg0` — туннель AmneziaWG в Нидерланды, который держит `make vpn` из `deploy/` SecondBrain (он же ставит AmneziaWG). Наружу клиенты видны с нидерландского адреса; если `awg0` лежит, интернета через VPN нет вовсе, в обход по российскому адресу трафик не пойдёт.

- `group_vars/all/vpn.yml` — серверы и клиенты. `awg1` — AmneziaWG для Mac и iPhone, `awg2` — обычный WireGuard для MikroTik (RouterOS не умеет AmneziaWG).
- `make vpn` поднимает серверы (`awg-quick@awg1`, `@awg2`), открывает их UDP-порты в ufw, включает форвардинг и кладёт профили в `vpn-profiles/` (в git не попадает: в профилях приватные ключи). Ключи и параметры обфускации создаются при первом прогоне и живут на сервере в `/etc/amnezia/amneziawg/<сервер>/`, повторные прогоны их не меняют.
- Новое устройство — строка в `clients` со своим последним октетом и `make vpn`. Убранное из списка устройство сервер больше не пускает.
- Mac и iPhone: `<имя>.conf` импортировать в AmneziaVPN; на iPhone проще отсканировать `<имя>.png` — QR с тем же профилем (его рисует `qrencode` на управляющей машине, `brew install qrencode`). Что идёт через VPN — в приложении: раздельное туннелирование, режим «только адреса из списка». На macOS и iOS оно работает по адресам и подсетям (сайт при добавлении превращается в IP), не по приложениям.
- MikroTik: `mikrotik.rsc` — команды для RouterOS 7 (интерфейс, пир, адрес, masquerade). Какой трафик пускать в туннель, настраивается на самом роутере.
- Сам хост тоже выходит наружу через `awg0`. Сайты, которые не пускают нидерландский адрес, перечислены у сервиса в `direct` (у `budget` — `api.zenmoney.ru`: с 30 октября 2026 года ZenMoney не принимает соединения с NL-адреса). Роль `direct` ставит скрипт `/usr/local/sbin/direct-routes` и таймер: при загрузке и раз в час скрипт заново узнаёт адреса этих сайтов и держит для каждого `ip rule … iif lo lookup main` с приоритетом 90. Так до них ходит только сам хост и с российского адреса, а клиенты VPN по-прежнему выходят через `awg0`. Роль входит в `make deploy`; одни правила, без деплоя сервисов, — `make direct`.

## С нуля

На управляющей машине: `ansible` (ansible-core ≥ 2.15), коллекции `ansible.posix` и `community.general`, ssh-ключ админа сервера. `cp inventory.example.yml inventory.local.yml` и заполнить.
