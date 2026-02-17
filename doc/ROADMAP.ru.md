dart_swagger_to_api_client — Дорожная карта
===========================================

Этот документ описывает поэтапное развитие отдельного пакета `dart_swagger_to_api_client`,
который строится поверх `dart_swagger_to_models` и отвечает за генерацию
типобезопасного HTTP‑клиента из OpenAPI/Swagger‑спецификаций.

Ключевая идея: **модели и клиент — это разные слои**.

- `dart_swagger_to_models` — отвечает за генерацию null‑safe моделей.
- `dart_swagger_to_api_client` — использует эти модели и генерирует API‑клиент
  (классы `ApiClient`, `UsersApi`, `OrdersApi`, эндпоинт‑методы и т.д.).

Ниже — план версий v0.1–v0.5+.

**Статус реализации**: ✅ v0.1 полностью завершён, частично реализованы v0.2 и v0.4.2.

## v0.1 — Minimal Viable Client (MVP, только `http`) ✅ ЗАВЕРШЕНО

**Цель**: получить рабочий, но минималистичный API‑клиент поверх уже сгенерированных моделей.

### 0.1.1 Базовые типы и инфраструктура ✅

- `lib/src/config/`:
  - ✅ `ApiClientConfig` — базовый URL, заголовки по умолчанию, таймаут, auth, HTTP‑адаптер.
  - ✅ `AuthConfig` — API key / bearer token.
- `lib/src/core/`:
  - ✅ `HttpClientAdapter`, `HttpRequest`, `HttpResponse`.
  - ✅ Конкретный адаптер `HttpHttpClientAdapter` на базе `package:http`.
- Простая авторизация:
  - ✅ API key в header/query (строки из `AuthConfig`).
  - ✅ Bearer token из `AuthConfig` (пока без env‑подстановок).

### 0.1.2 Разбор спеки и простейшая генерация ✅

- ✅ `spec_loader.dart` — минимум, чтобы прочитать OpenAPI/Swagger и пройтись по `paths`.
- ✅ `client_generator.dart`:
  - Генерация одного общего `ApiClient` с `DefaultApi` классом.
- ✅ `endpoint_method_generator.dart`:
  - Методы для `GET`/`POST`/`PUT`/`DELETE`/`PATCH`:
    - ✅ path‑параметры, query‑параметры (примитивные типы).
    - ✅ один JSON‑body (`requestBody` → `Map<String, dynamic>`).
    - ✅ десериализация ответа: `Future<void>`, `Future<Map<String, dynamic>>`, `Future<List<Map<String, dynamic>>>`.

### 0.1.3 CLI и конфиг (минимум) ✅

- ✅ `bin/dart_swagger_to_api_client.dart`:
  - Флаги: `--input`, `--output-dir`, `--config`, `--verbose`, `--quiet`.
- ✅ `dart_swagger_to_api_client.yaml` (минимальный поднабор):
  - `input`, `outputDir`, `client.baseUrl`, `client.headers`, `client.auth`.
- ✅ Приоритет: **CLI > config > defaults** (как в `dart_swagger_to_models`).

### 0.1.4 Пример и smoke‑тест ✅

- ✅ Пример в `example/`:
  - Минимальная OpenAPI‑спека для тестирования.
  - Генерация в `example/generated/` клиента.

## v0.2 — Укрепление ядра и расширение HTTP‑слоя

**Цель**: сделать ядро пригодным для реального прод‑использования.

**Статус**: ⚠️ Частично реализовано (0.2.1, 0.2.2 частично, 0.2.3 полностью)

### 0.2.1 Расширение `HttpClientAdapter` ⚠️ Частично

- ✅ Возможность проброса «сырого» клиента (`http.Client`).
- ✅ Базовая стратегия обработки ошибок:
  - ✅ маппинг статусов (2xx / 4xx / 5xx) → свои исключения
    (`ApiClientException`, `ApiServerException`, `ApiAuthException`).
- ❌ Поддержка таймаутов (из `ApiClientConfig.timeout`) — **TODO**: нужно интегрировать в `HttpHttpClientAdapter.send()`.

### 0.2.2 Улучшение генерации endpoint‑методов ⚠️ Частично

- ✅ Поддержка нескольких `response` схем (выбор по коду 200/201/204).
- ✅ `204 No Content` → `Future<void>`.
- ✅ Улучшение сигнатур методов:
  - ✅ явное разделение `required` / `optional` аргументов.
  - ✅ `Future<void>` для методов без полезного тела ответа.
- ❌ `application/x-www-form-urlencoded` / простых форм — **TODO**.

### 0.2.3 DX и логирование ✅ ЗАВЕРШЕНО

- ✅ Флаги CLI: `--verbose`, `--quiet`.
- ✅ Человеческие сообщения:
  - ✅ валидация спецификации (`SpecValidator`) с детальными предупреждениями;
  - ✅ когда endpoint пропущен (unsupported feature);
  - ✅ когда не удалось подобрать модель ответа/запроса.

## v0.3 — Поддержка нескольких HTTP‑клиентов и кастомизация

**Цель**: сделать пакет гибким и расширяемым, как `dart_swagger_to_models` со стилями.

### 0.3.1 Адаптеры `dio` и кастомные клиенты

- `DioHttpClientAdapter`:
  - маппинг `HttpRequest`/`HttpResponse` на `dio`.
- Поддержка `http.adapter` в конфиге:
  - `http`, `dio`, `custom`.
- Для `custom`:
  - строковый идентификатор Dart‑типа (`customAdapterType`);
  - генерация кода, ожидающего, что пользователь сам передаст экземпляр адаптера
    в `ApiClientConfig`.

### 0.3.2 Конфигурация клиента и окружения

- Расширить конфиг:
  - `client.auth.bearerTokenEnv` (как в `API_CLIENT_NOTES.md`);
  - профили `baseUrl` (например, `dev`, `staging`, `prod`).
- Простая поддержка переключения окружений:
  - флаг CLI `--env` → выбор профиля из конфига.

### 0.3.3 Генерация удобного фасада

- Доработать `ApiClient`:
  - метод `close()` для адаптеров, которым нужен dispose;
  - «scoped» клиент с переопределёнными заголовками
    (например, `client.withHeaders({...})` возвращает обёртку).

## v0.4 — OpenAPI‑feature completeness и связка с моделями

**Цель**: покрыть основные реальные API‑кейсы и сделать связку `models + api_client` удобной.

### 0.4.1 Улучшенная поддержка OpenAPI

- Более точная работа с:
  - `parameters` (path, query, header, cookie);
  - `requestBody` с несколькими `content` типами
    (выбор `application/json` / `multipart/form-data`).
- Базовая поддержка пагинации:
  - обнаружение типичных паттернов (query `page`, `limit`, `offset`);
  - генерация helper‑методов (опционально, через флаг).

### 0.4.2 Тесная интеграция с `dart_swagger_to_models` ⚠️ Частично

- ✅ Инфраструктура для интеграции:
  - ✅ `ModelsResolver` интерфейс для разрешения `$ref` → Dart типы.
  - ✅ `ModelsConfig`, `ModelsConfigLoader` для чтения `dart_swagger_to_models.yaml`.
  - ✅ `NoOpModelsResolver` как заглушка (используется по умолчанию).
- ❌ Реальная интеграция:
  - ❌ Реализация `ModelsResolver`, которая читает кеш `.dart_swagger_to_models.cache`
    или конфиг `dart_swagger_to_models.yaml`, чтобы находить пути к сгенерированным моделям.
  - ❌ Генерация методов с реальными типами моделей вместо `Map<String, dynamic>`.
  - ❌ Автоматическое добавление импортов для моделей.

### 0.4.3 Документация и примеры

- Полный README:
  - end‑to‑end сценарий: spec → models → api_client → вызов API.
- 1–2 расширенных примера:
  - пример с авторизацией;
  - пример с пагинацией и обработкой ошибок.

## v0.5+ — Расширенный DX, тестирование и «полировка»

Дальнейшие версии можно развивать итеративно, в духе `dart_swagger_to_models`:

- **0.5.0 Тестовый контур и стабильность** ⚠️ Частично
  - ✅ Unit‑тесты для генераторов (`endpoint_method_generator_test.dart`).
  - ✅ Интеграционные тесты для полного цикла генерации (`api_client_generator_test.dart`).
  - ✅ Тесты для конфигурации и валидации.
  - ❌ Интеграционные тесты на фейковый OpenAPI или локальный тестовый сервер — **TODO**.
  - ❌ Регрессионные тесты для разных версий OpenAPI/Swagger — **TODO**.

- **0.6.0 Advanced DX**
  - Watch‑режим (`--watch`) для авто‑регенерации клиента.
  - Предпросмотр diff перед перезаписью файлов.
  - Интерактивный режим выбора части endpoints.

- **0.7.0 Middleware и ретраи**
  - Middleware‑цепочка для запросов/ответов:
    - логирование, ретраи, rate‑limit обработка.
  - Подключаемые пользовательские интерсепторы.

- **0.8.0 Интеграции**
  - Примеры/генерация кода для интеграции со state management (Riverpod/BLoC) поверх клиента.
  - CI‑шаблоны для автоматической регенерации клиента.

