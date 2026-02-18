# Руководство по использованию

Полное руководство по использованию `dart_swagger_to_api_client` для генерации типобезопасных HTTP-клиентов из OpenAPI/Swagger спецификаций.

## Содержание

1. [Установка](#установка)
2. [Быстрый старт](#быстрый-старт)
3. [Конфигурация](#конфигурация)
4. [Использование CLI](#использование-cli)
5. [Использование сгенерированного клиента](#использование-сгенерированного-клиента)
6. [HTTP адаптеры](#http-адаптеры)
7. [Аутентификация](#аутентификация)
8. [Middleware](#middleware)
9. [Профили окружений](#профили-окружений)
10. [Watch-режим](#watch-режим)
11. [Интеграция с CI/CD](#интеграция-с-cicd)
12. [Интеграция со state management](#интеграция-со-state-management)
13. [Решение проблем](#решение-проблем)

## Установка

Добавьте `dart_swagger_to_api_client` в ваш `pubspec.yaml`:

```yaml
dev_dependencies:
  dart_swagger_to_models: ^0.9.0
  dart_swagger_to_api_client: ^1.0.0
```

Затем выполните:

```bash
dart pub get
```

## Быстрый старт

### Шаг 1: Генерация моделей

Сначала сгенерируйте модели с помощью `dart_swagger_to_models`:

```bash
dart run dart_swagger_to_models:dart_swagger_to_models \
  --input swagger/api.yaml \
  --output-dir lib/models \
  --style json_serializable
```

### Шаг 2: Генерация API клиента

Сгенерируйте API клиент:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

### Шаг 3: Использование клиента

```dart
import 'package:my_app/api_client/api_client.dart';
import 'package:my_app/models/user.dart';

final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    bearerToken: 'your-token-here',
  ),
);

final client = ApiClient(config);

try {
  final List<User> users = await client.defaultApi.getUsers();
  print('Users: $users');
} finally {
  await client.close();
}
```

## Конфигурация

### Файл конфигурации

Создайте `dart_swagger_to_api_client.yaml` в корне проекта:

```yaml
input: swagger/api.yaml
outputDir: lib/api_client

client:
  baseUrl: https://api.example.com
  headers:
    User-Agent: my-app/1.0.0
  timeout: 30000  # миллисекунды
  auth:
    bearerToken: your-token-here
    # или
    bearerTokenEnv: API_BEARER_TOKEN

http:
  adapter: http  # или 'dio', 'custom'
  customAdapterType: MyCustomAdapter  # если используется custom

environments:
  dev:
    baseUrl: https://dev-api.example.com
    headers:
      X-Environment: dev
  prod:
    baseUrl: https://api.example.com
    auth:
      bearerTokenEnv: PROD_BEARER_TOKEN
```

### Использование конфигурации

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

## Использование CLI

### Базовая команда

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

### Все опции

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \          # Обязательно: путь к OpenAPI спецификации
  --output-dir lib/api_client \       # Обязательно: директория вывода
  --config config.yaml \              # Опционально: файл конфигурации
  --env prod \                        # Опционально: профиль окружения
  --watch \                           # Опционально: watch-режим
  --verbose \                         # Опционально: подробный вывод
  --quiet                             # Опционально: тихий режим
```

### Детали опций

| Опция | Короткая | Обязательно | Описание |
|-------|----------|-------------|----------|
| `--input` | `-i` | Да | Путь к OpenAPI/Swagger спецификации (YAML или JSON) |
| `--output-dir` | - | Да | Директория, куда будет сгенерирован код |
| `--config` | `-c` | Нет | Путь к файлу конфигурации |
| `--env` | - | Нет | Имя профиля окружения (dev, staging, prod и т.д.) |
| `--watch` | `-w` | Нет | Включить watch-режим для автоматической регенерации |
| `--verbose` | `-v` | Нет | Показывать подробный вывод, включая предупреждения |
| `--quiet` | `-q` | Нет | Показывать только ошибки, скрывать предупреждения |
| `--help` | `-h` | Нет | Показать справку по использованию |

## Использование сгенерированного клиента

### Базовые API вызовы

```dart
final client = ApiClient(config);

// GET запрос
final users = await client.defaultApi.getUsers();

// GET с параметрами
final user = await client.defaultApi.getUser(userId: '123');

// POST запрос
final newUser = await client.defaultApi.createUser(
  body: User(name: 'John', email: 'john@example.com'),
);

// PUT запрос
final updatedUser = await client.defaultApi.updateUser(
  userId: '123',
  body: User(name: 'Jane', email: 'jane@example.com'),
);

// DELETE запрос
await client.defaultApi.deleteUser(userId: '123');
```

### Типы ответов

Генератор автоматически определяет типы ответов:

- `Future<void>` — для ответов 204 No Content
- `Future<Map<String, dynamic>>` — для объектных ответов
- `Future<List<Map<String, dynamic>>>` — для массивов ответов
- `Future<ModelType>` — при интеграции с моделями
- `Future<List<ModelType>>` — для массивов моделей

### Обработка ошибок

```dart
try {
  final user = await client.defaultApi.getUser(userId: '123');
} on ApiAuthException catch (e) {
  // Обработка ошибок аутентификации (401, 403)
  print('Ошибка аутентификации: ${e.message}');
} on ApiServerException catch (e) {
  // Обработка ошибок сервера (5xx)
  print('Ошибка сервера: ${e.message}');
} on TimeoutException catch (e) {
  // Обработка таймаутов
  print('Запрос превысил время ожидания: ${e.message}');
} on ApiClientException catch (e) {
  // Обработка других ошибок клиента
  print('Ошибка клиента: ${e.message}');
}
```

### Управление ресурсами

Всегда закрывайте клиент после использования:

```dart
final client = ApiClient(config);
try {
  // Использование клиента
} finally {
  await client.close(); // Освобождает ресурсы адаптера
}
```

### Scoped клиенты

Создавайте клиенты с дополнительными заголовками:

```dart
final baseClient = ApiClient(config);

final scopedClient = baseClient.withHeaders({
  'X-Request-ID': '123',
  'X-User-ID': 'user-456',
});

// Все запросы через scopedClient включают эти заголовки
final users = await scopedClient.defaultApi.getUsers();
```

## HTTP адаптеры

### Адаптер по умолчанию (package:http)

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  // Использует HttpHttpClientAdapter по умолчанию
);
```

### Dio адаптер

```dart
import 'package:dio/dio.dart';
import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

final dio = Dio();
final adapter = DioHttpClientAdapter(dio: dio);

final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  httpClientAdapter: adapter,
);
```

### Кастомный адаптер

```dart
class MyCustomAdapter implements HttpClientAdapter {
  @override
  Future<HttpResponse> send(HttpRequest request) async {
    // Ваша кастомная реализация
    // ...
  }

  @override
  Future<void> close() async {
    // Очистка при необходимости
  }
}

final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  httpClientAdapter: MyCustomAdapter(),
);
```

## Аутентификация

### Bearer Token

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    bearerToken: 'your-token-here',
  ),
);
```

### Bearer Token из переменной окружения

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    bearerTokenEnv: 'API_BEARER_TOKEN', // Читается из окружения
  ),
);
```

### API Key в заголовке

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    apiKeyHeader: 'X-API-Key',
    apiKey: 'your-api-key',
  ),
);
```

### API Key в query параметре

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    apiKeyQuery: 'api_key',
    apiKey: 'your-api-key',
  ),
);
```

## Middleware

### Логирование

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    LoggingInterceptor.console(
      logHeaders: true,
      logBody: false,
    ),
  ],
  responseInterceptors: [
    LoggingInterceptor.console(),
  ],
);
```

### Ретраи

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  responseInterceptors: [
    RetryInterceptor(
      maxRetries: 3,
      retryableStatusCodes: {500, 502, 503, 504},
      retryableErrors: {TimeoutException},
      baseDelayMs: 1000,
      maxDelayMs: 10000,
    ),
  ],
);
```

### Rate Limiting

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    RateLimitInterceptor(
      maxRequests: 100,
      window: Duration(minutes: 1),
    ),
  ],
);
```

### Circuit Breaker

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    CircuitBreakerInterceptor(
      failureThreshold: 5,
      timeout: Duration(seconds: 60),
      resetTimeout: Duration(seconds: 30),
    ),
  ],
  responseInterceptors: [
    CircuitBreakerInterceptor(
      failureThreshold: 5,
      timeout: Duration(seconds: 60),
      resetTimeout: Duration(seconds: 30),
    ),
  ],
);
```

### Трансформации запросов/ответов

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    TransformerInterceptor(
      requestTransformer: RequestTransformers.addHeaders({
        'X-Request-ID': generateId(),
      }),
    ),
  ],
  responseInterceptors: [
    TransformerInterceptor(
      responseTransformer: ResponseTransformers.normalizeStatusCodes({
        201: 200,
        204: 200,
      }),
    ),
  ],
);
```

## Профили окружений

### Конфигурация

```yaml
# dart_swagger_to_api_client.yaml
client:
  baseUrl: https://api.example.com
  headers:
    User-Agent: my-app/1.0.0

environments:
  dev:
    baseUrl: https://dev-api.example.com
    headers:
      X-Environment: dev
  staging:
    baseUrl: https://staging-api.example.com
    headers:
      X-Environment: staging
  prod:
    baseUrl: https://api.example.com
    auth:
      bearerTokenEnv: PROD_BEARER_TOKEN
```

### Использование

```bash
# Разработка
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --env dev

# Продакшн
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

## Watch-режим

Автоматически регенерируйте клиент при изменении спецификации или конфигурации:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --watch
```

**Возможности:**
- Один запуск генерации на старте
- Отслеживание изменений в spec и config файлах
- Автоматическая перезагрузка конфигурации при изменении
- Debounce: 500ms для предотвращения множественных регенераций
- Нажмите `Ctrl+C` для остановки

**Примечание:** Watch-режим работает только с локальными файлами, не с URL.

## Интеграция с CI/CD

### GitHub Actions

Скопируйте `.github/workflows/regenerate-client.yml` в ваш репозиторий:

```yaml
# .github/workflows/regenerate-client.yml
name: Regenerate API Client

on:
  push:
    paths:
      - 'swagger/**'
```

### GitLab CI

Скопируйте `.gitlab-ci.yml` в корень репозитория.

См. `ci/README.md` для подробных инструкций по настройке.

## Интеграция со state management

### Riverpod

См. `example/riverpod_integration_example.dart` для полных примеров:

- `Provider` и `FutureProvider` для простых случаев
- `StateNotifier` для сложного управления состоянием
- Обработка ошибок и состояний загрузки

### BLoC

См. `example/bloc_integration_example.dart` для полных примеров:

- Определения Events и States
- Реализации BLoC
- Паттерн Repository
- Интеграция с виджетами

## Решение проблем

### Частые проблемы

**Проблема: Модели не найдены**

**Решение:** Убедитесь, что вы сначала сгенерировали модели с помощью `dart_swagger_to_models`, и что файл конфигурации `dart_swagger_to_models.yaml` существует.

**Проблема: Отсутствует operationId**

**Решение:** Добавьте `operationId` ко всем операциям в вашей OpenAPI спецификации. Операции без `operationId` пропускаются.

**Проблема: Неподдерживаемый тип контента**

**Решение:** В настоящее время поддерживаются следующие типы контента:
- `application/json`
- `application/x-www-form-urlencoded`
- `multipart/form-data`

**Проблема: Watch-режим не работает**

**Решение:** Убедитесь, что вы используете локальный путь к файлу, а не URL. Watch-режим не поддерживает удаленные URL.

### Получение помощи

- Проверьте [FAQ](doc/ru/FAQ.md)
- См. [Руководство по решению проблем](doc/ru/TROUBLESHOOTING.md)
- Откройте issue на [GitHub](https://github.com/AlexGalitsky/dart_swagger_to_api_client/issues)
