# Комплексный аудит Vibemode Overlay

Дата: 26-06-2026
Объект: локальный Python-проект `Vibemode Overlay`
Режим: senior engineering + QA + UI/UX + security review
Границы: защитный аудит без DDoS, обхода авторизации, кражи данных или доступа к чужой информации

## Короткий статус

Проект остаётся local-first: пароль не вводится в интерфейс оверлея, cookies и browser-profile остаются на компьютере пользователя, raw text кабинета не печатается в консоль и не пишется в debug log целиком. Основные риски сейчас не в явной утечке секретов, а в цепочке автообновления, macOS parity, устойчивости запуска после сна/подвисшей страницы и публичной чистоте документации.

Текущая локальная ветка содержит незапушенные изменения v2.2. Проверки после правок аудита: `scripts/check.ps1` -> `133 tests OK`, `git diff --check` -> PASS, `scripts/package-release.ps1` -> PASS. ZIP privacy-scan не нашёл browser-profile, локальные state/log/history файлы, `.env`, HAR/trace/cookies, `PROJECT_STATE.md`, `HANDOFF.md` или audit report внутри релизного архива.

## 10 проблем и рисков

### 1. macOS ZIP update мог идти без SHA256

- Серьёзность: high.
- Где: `scripts/update-and-restart.sh`.
- Почему это проблема: публичное автообновление должно проверять целостность ZIP на обеих платформах одинаково.
- Как исправлено: macOS updater теперь требует SHA256 по умолчанию, умеет читать `.sha256` sidecar и допускает update без checksum только через явный dev-флаг `--allow-unverified-zip`.
- Проверки: `tests/test_scripts.py`, `scripts/check.ps1`.

### 2. macOS `.app` launcher вычислял неправильный корень проекта

- Серьёзность: high.
- Где: `scripts/create-desktop-shortcut.sh`.
- Почему это проблема: `.app` создаётся в `~/Applications`, а старый launch-скрипт мог искать `scripts/run-overlay.sh` не в папке проекта.
- Как исправлено: launcher записывает реальный project root при создании `.app`.
- Проверки: `tests/test_scripts.py`, macOS ручной запуск `Vibemode.app` нужен перед релизом.

### 3. macOS local popover actions не имели token-защиты

- Серьёзность: medium/high.
- Где: `src/neurogate_usage_overlay/popover_server.py`, `src/neurogate_usage_overlay/macos_popover.py`.
- Почему это проблема: локальный `127.0.0.1`-сервер принимал action-запросы без nonce; случайная локальная страница могла бы попытаться вызвать action, если угадает порт.
- Как исправлено: добавлен per-session token, `/data`, `/action/*` и `/resize/*` требуют token, GET-actions запрещены.
- Проверки: `tests/test_popover_server.py`, `scripts/check.ps1`.

### 4. Windows context menu мог открываться за границей экрана

- Серьёзность: medium.
- Где: `src/neurogate_usage_overlay/overlay.py`.
- Почему это проблема: меню могло оказаться у края экрана и стать неудобным для выбора/закрытия.
- Как исправлено: добавлен clamp позиции popup-меню по размеру экрана.
- Проверки: `tests/test_overlay.py`.

### 5. macOS popover отставал от Windows по отображению `остаток/общий лимит`

- Серьёзность: medium.
- Где: `src/neurogate_usage_overlay/popover_server.py`.
- Почему это проблема: Windows v2.2 показывает `114.0M/120M`, а macOS показывал только `106M ост.`, что создаёт разный смысл интерфейса.
- Как исправлено: HTML popover использует `остаток/общий лимит`, если есть `limit_total`.
- Проверки: `tests/test_popover_server.py`; визуальный macOS smoke нужен перед релизом.

### 6. Старт и чтение кабинета могли долго ждать подвисшую страницу

- Серьёзность: medium/high.
- Где: `src/neurogate_usage_overlay/browser_reader.py`.
- Почему это проблема: `_wait_for_usage_text()` делает до 30 попыток, а `inner_text()` использует общий timeout 45 секунд. При плохом состоянии страницы/после сна это может визуально подвесить запуск или задержать вход.
- Как исправлено: чтение `body.inner_text()` использует короткий polling-timeout `BODY_TEXT_TIMEOUT_MS = 3000`, общий timeout навигации не менялся.
- Проверки: `tests/test_browser_reader.py`; ручной сценарий после сна Windows всё ещё нужен.

### 7. Скрипты запуска имели широкий fallback kill по имени

- Серьёзность: medium.
- Где: `scripts/run-overlay.sh`, `scripts/run-overlay.ps1`.
- Почему это проблема: `pgrep -f '...vibemode...'` может теоретически задеть чужой процесс с похожей командной строкой.
- Как исправлено: fallback сужен до точного `python -m neurogate_usage_overlay` или алиаса внутри папки проекта; Chrome остаётся по собственному profile path.
- Проверки: `tests/test_scripts.py`, ручной macOS restart/update ещё нужен.

### 8. Daily-limit parity на macOS неполный

- Серьёзность: medium.
- Где: `src/neurogate_usage_overlay/overlay.py`, `src/neurogate_usage_overlay/popover_server.py`.
- Почему это проблема: Windows имеет компактную третью строку `лимит/день`; macOS сейчас больше завязан на карточки/actions и требует отдельного визуального smoke.
- Как исправить: добавить явную daily-limit карточку с теми же spent/limit/percent правилами и цветовой шкалой, либо честно задокументировать отличие.
- Проверки: `tests/test_popover_server.py`, macOS screenshot/manual QA.

### 9. CI не проверял macOS путь

- Серьёзность: medium.
- Где: `.github/workflows/ci.yml`.
- Почему это проблема: macOS UI и shell scripts уже часть продукта, но GitHub Actions гоняет только Windows.
- Как исправлено: добавлен `macos-latest` job с Python 3.12, установкой `.[macos]`, compile и macOS-safe unit tests.
- Проверки: локально проверена YAML-правка и общий `scripts/check.ps1`; зелёный GitHub Actions на macOS можно подтвердить только после push.

### 10. В корне были устаревшие project-state/handoff/report файлы со старым брендом

- Серьёзность: low/medium.
- Где: `PROJECT_STATE.md`, `HANDOFF.md`, старый `security_best_practices_report.md`.
- Почему это проблема: публичный репозиторий может показывать пользователям старые NeuroGate-ссылки и старые release-правила.
- Как исправлено: `PROJECT_STATE.md` и `HANDOFF.md` обновлены под Vibemode/v2.2, `security_best_practices_report.md` заменён текущим аудитом, а `scripts/package-release.ps1` исключает эти внутренние файлы из ZIP.
- Проверки: `tests/test_scripts.py`, `scripts/package-release.ps1`, ZIP privacy-scan.

## Быстрые исправления на 1-2 часа

- Сделано: обновлены `PROJECT_STATE.md` и `HANDOFF.md`, внутренние файлы исключены из публичного ZIP.
- Сделано: добавлен macOS CI job.
- Сделано: прогнан `scripts/package-release.ps1`, создан `dist\vibemode-v2.2.zip` и `.sha256`.

## Глубокие архитектурные улучшения

- Вынести чтение Vibemode API в отдельный adapter с contract fixtures.
- Добавить long-run performance harness на 60-90 минут для drag/refresh/profile-size.
- Сделать единый renderer model для Windows/macOS, чтобы parity не расходился.
- Добавить подписанные release artifacts или установщик с подписью для Windows/macOS.
- Добавить локальный diagnostics snapshot без приватных данных: длительность refresh, worker queue, размер profile/cache.

## Что нельзя проверить без доступа

- Реальный вход и смену аккаунта в Vibemode ЛК.
- Консоль/Network кабинета на живой сессии.
- Поведение после сна Windows на реальном компьютере владельца.
- Визуальный macOS popover и запуск `.app` на macOS.
- End-to-end GitHub Release update с настоящим ZIP asset и `.sha256`.

## GOAL

Устранить найденные проблемы так, чтобы Vibemode Overlay был готов к стабильному публичному релизу:

- critical/high пункты 1-3 исправлены и покрыты тестами;
- medium пункты 4-8 либо исправлены, либо явно переведены в release checklist с ручной проверкой;
- `scripts/check.ps1` и `git diff --check` проходят;
- при изменении релизных архивов проходит `scripts/package-release.ps1`;
- README, CHANGELOG, SECURITY/PRIVACY/ARCHITECTURE/PUBLISHING отражают фактическое поведение;
- владелец подтверждает ручные сценарии: вход, смена аккаунта, сон/пробуждение, drag, меню, update notice.
