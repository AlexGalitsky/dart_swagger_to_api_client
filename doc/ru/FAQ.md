# Часто задаваемые вопросы (FAQ)

Частые вопросы и ответы о `dart_swagger_to_api_client`.

## Общие вопросы

### Что такое dart_swagger_to_api_client?

`dart_swagger_to_api_client` — это генератор кода, который создает типобезопасные HTTP API клиенты из OpenAPI/Swagger спецификаций. Работает с `dart_swagger_to_models` для генерации полного стека: модели + API клиент.

### Чем он отличается от dart_swagger_to_models?

- `dart_swagger_to_models`: Генерирует Dart классы моделей из OpenAPI схем
- `dart_swagger_to_api_client`: Генерирует HTTP клиент код, который использует эти модели

Это отдельные пакеты, которые работают вместе.

### Какие версии OpenAPI поддерживаются?

- OpenAPI 3.0.0
- OpenAPI 3.1.0
- Swagger 2.0 (базовая поддержка)

## Генерация

### Почему некоторые эндпоинты отсутствуют в сгенерированном клиенте?

Эндпоинты без `operationId` пропускаются. Добавьте `operationId` ко всем операциям в вашей OpenAPI спецификации:

```yaml
paths:
  /users:
    get:
      operationId: getUsers  # Обязательно!
      responses:
        '200':
          description: OK
```

### Как сгенерировать модели и клиент вместе?

1. Сначала сгенерируйте модели:
```bash
dart run dart_swagger_to_models:dart_swagger_to_models \
  --input swagger/api.yaml \
  --output-dir lib/models
```

2. Затем сгенерируйте клиент:
```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

Генератор клиента автоматически обнаружит и использует сгенерированные модели.

### Могу ли я использовать клиент без генерации моделей?

Да! Клиент будет использовать `Map<String, dynamic>` для request/response тел, когда модели недоступны.

## Конфигурация

### Как использовать разные конфигурации для dev/staging/prod?

Используйте профили окружений в вашем конфигурационном файле:

```yaml
# dart_swagger_to_api_client.yaml
environments:
  dev:
    baseUrl: https://dev-api.example.com
  prod:
    baseUrl: https://api.example.com
```

Затем используйте флаг `--env`:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

### Как использовать bearer token из переменных окружения?

```yaml
client:
  auth:
    bearerTokenEnv: API_BEARER_TOKEN
```

Токен будет прочитан из переменной окружения `API_BEARER_TOKEN` во время выполнения.

## HTTP адаптеры

### Какой HTTP адаптер использовать?

- **`http`** (по умолчанию): Простой, легковесный, хорош для большинства случаев
- **`dio`**: Больше функций (interceptors, transformers), лучше для сложных сценариев
- **Custom**: Для специальных требований

### Как использовать Dio адаптер?

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

### Могу ли я использовать кастомный HTTP клиент?

Да! Реализуйте `HttpClientAdapter`:

```dart
class MyCustomAdapter implements HttpClientAdapter {
  @override
  Future<HttpResponse> send(HttpRequest request) async {
    // Ваша реализация
  }
}
```

## Middleware

### Как добавить логирование?

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    LoggingInterceptor.console(),
  ],
  responseInterceptors: [
    LoggingInterceptor.console(),
  ],
);
```

### Как добавить ретраи?

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  responseInterceptors: [
    RetryInterceptor(
      maxRetries: 3,
      retryableStatusCodes: {500, 502, 503, 504},
    ),
  ],
);
```

### Могу ли я создать кастомный middleware?

Да! Реализуйте `RequestInterceptor` или `ResponseInterceptor`:

```dart
class MyMiddleware implements RequestInterceptor {
  @override
  Future<HttpRequest> onRequest(HttpRequest request) async {
    // Модифицировать запрос
    return request;
  }
}
```

## Ошибки

### Какие исключения могут быть выброшены?

- `ApiClientException`: Базовое исключение для всех ошибок клиента
- `ApiServerException`: Ошибки сервера (5xx статус коды)
- `ApiAuthException`: Ошибки аутентификации (401, 403)
- `TimeoutException`: Ошибки таймаута запроса

### Как обрабатывать ошибки?

```dart
try {
  final user = await client.defaultApi.getUser(userId: '123');
} on ApiAuthException catch (e) {
  // Обработка ошибок аутентификации
} on ApiServerException catch (e) {
  // Обработка ошибок сервера
} on TimeoutException catch (e) {
  // Обработка таймаутов
}
```

## Интеграция с моделями

### Как работает интеграция с моделями?

1. Сгенерируйте модели с помощью `dart_swagger_to_models`
2. Генератор клиента сканирует `dart_swagger_to_models.yaml`
3. Если найден, использует `FileBasedModelsResolver` для разрешения `$ref` в типы моделей
4. Сгенерированные методы возвращают типы моделей вместо `Map<String, dynamic>`

### Что если модели не найдены?

Клиент будет использовать `Map<String, dynamic>` для request/response тел. Это нормально для простых случаев использования.

## Watch-режим

### Как работает watch-режим?

Watch-режим отслеживает изменения в spec и config файлах и автоматически регенерирует клиент:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --watch
```

### Могу ли я использовать watch-режим с удаленными URL?

Нет, watch-режим работает только с локальными файлами. Используйте CI/CD для удаленных спецификаций.

## CI/CD

### Как настроить автоматическую регенерацию?

См. `ci/README.md` для подробных инструкций. Шаблоны доступны для:
- GitHub Actions
- GitLab CI

### Могу ли я регенерировать по расписанию?

Да! Используйте шаблоны scheduled workflows в `.github/workflows/`.

## State Management

### Как использовать с Riverpod?

См. `example/riverpod_integration_example.dart` для полных примеров.

### Как использовать с BLoC?

См. `example/bloc_integration_example.dart` для полных примеров.

## Решение проблем

### Сгенерированный код имеет ошибки

1. Проверьте, что ваша OpenAPI спецификация валидна
2. Убедитесь, что все операции имеют `operationId`
3. Проверьте неподдерживаемые функции (см. предупреждения с `--verbose`)

### Модели не используются

1. Убедитесь, что `dart_swagger_to_models.yaml` существует
2. Проверьте, что модели были сгенерированы в ожидаемой директории
3. Убедитесь, что `outputDir` в конфигурации моделей соответствует фактическому расположению

### Watch-режим не работает

1. Убедитесь, что вы используете локальный путь к файлу, а не URL
2. Проверьте права доступа к файлам
3. Попробуйте запустить без watch-режима сначала

## Получение помощи

- Проверьте [Руководство по решению проблем](doc/ru/TROUBLESHOOTING.md)
- См. [Руководство по использованию](doc/ru/USAGE.md)
- Откройте issue на [GitHub](https://github.com/AlexGalitsky/dart_swagger_to_api_client/issues)
