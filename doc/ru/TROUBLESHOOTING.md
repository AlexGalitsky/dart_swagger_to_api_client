# Руководство по решению проблем

Частые проблемы и решения при использовании `dart_swagger_to_api_client`.

## Проблемы генерации

### Эндпоинты не генерируются

**Симптомы:** Сгенерированный `api_client.dart` не содержит методов в классе `DefaultApi`.

**Возможные причины:**
1. Отсутствует `operationId` в операциях
2. Неподдерживаемые HTTP методы
3. Ошибки валидации спецификации

**Решения:**
1. Добавьте `operationId` ко всем операциям:
```yaml
paths:
  /users:
    get:
      operationId: getUsers  # Обязательно!
```

2. Проверьте поддерживаемые HTTP методы: GET, POST, PUT, DELETE, PATCH

3. Запустите с `--verbose` чтобы увидеть предупреждения валидации:
```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --verbose
```

### Модели не используются

**Симптомы:** Сгенерированные методы возвращают `Map<String, dynamic>` вместо типов моделей.

**Возможные причины:**
1. Модели еще не сгенерированы
2. `dart_swagger_to_models.yaml` не найден
3. Неправильный `outputDir` в конфигурации моделей

**Решения:**
1. Сначала сгенерируйте модели:
```bash
dart run dart_swagger_to_models:dart_swagger_to_models \
  --input swagger/api.yaml \
  --output-dir lib/models
```

2. Убедитесь, что `dart_swagger_to_models.yaml` существует в корне проекта:
```yaml
outputDir: lib/models
```

3. Проверьте, что `outputDir` в конфигурации моделей соответствует месту генерации моделей

### Невалидная OpenAPI спецификация

**Симптомы:** Генерация завершается ошибками валидации.

**Решения:**
1. Валидируйте вашу спецификацию с помощью онлайн инструментов (например, Swagger Editor)
2. Проверьте обязательные поля: `openapi`, `info`, `paths`
3. Убедитесь, что все цели `$ref` существуют

## Проблемы времени выполнения

### Ошибки аутентификации

**Симптомы:** Выбрасывается `ApiAuthException` при запросах.

**Решения:**
1. Проверьте, что `AuthConfig` установлен правильно:
```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    bearerToken: 'your-token',
  ),
);
```

2. Если используете `bearerTokenEnv`, убедитесь, что переменная окружения установлена:
```bash
export API_BEARER_TOKEN=your-token
```

3. Проверьте, что токен валиден и не истек

### Ошибки таймаута

**Симптомы:** Выбрасывается `TimeoutException` при запросах.

**Решения:**
1. Увеличьте таймаут:
```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  timeout: Duration(seconds: 60),  // Увеличьте с 30s по умолчанию
);
```

2. Проверьте сетевое подключение
3. Убедитесь, что API сервер отвечает

### Ошибки сервера

**Симптомы:** Выбрасывается `ApiServerException` с 5xx статус кодами.

**Решения:**
1. Проверьте статус API сервера
2. Убедитесь, что формат запроса соответствует ожиданиям API
3. Используйте retry middleware для временных ошибок:
```dart
responseInterceptors: [
  RetryInterceptor(
    maxRetries: 3,
    retryableStatusCodes: {500, 502, 503, 504},
  ),
],
```

## Проблемы конфигурации

### Конфигурационный файл не найден

**Симптомы:** Предупреждения о отсутствующем конфигурационном файле.

**Решения:**
1. Создайте `dart_swagger_to_api_client.yaml` в корне проекта
2. Или укажите путь явно:
```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --config path/to/config.yaml
```

### Профиль окружения не найден

**Симптомы:** Предупреждение о отсутствующем профиле окружения.

**Решения:**
1. Проверьте, что имя профиля соответствует конфигурации:
```yaml
environments:
  dev:  # Используйте 'dev', а не 'development'
    baseUrl: https://dev-api.example.com
```

2. Убедитесь, что профиль определен в конфигурационном файле

### Значения конфигурации не применяются

**Симптомы:** Сгенерированный код не соответствует конфигурации.

**Решения:**
1. Помните приоритет: Аргументы CLI > Config > Defaults
2. Аргументы CLI переопределяют значения конфигурации
3. Проверьте синтаксис конфигурационного файла (важны отступы YAML)

## Проблемы Watch-режима

### Watch-режим не срабатывает

**Симптомы:** Изменения в spec файле не вызывают регенерацию.

**Решения:**
1. Убедитесь, что вы используете локальный путь к файлу, а не URL
2. Проверьте права доступа к файлам
3. Убедитесь, что файл сохраняется (некоторые редакторы требуют явного сохранения)

### Множественные регенерации

**Симптомы:** Клиент регенерируется несколько раз для одного изменения.

**Решения:**
- Это нормально из-за debounce (500ms). Несколько событий файловой системы могут вызвать несколько регенераций.
- Debounce предотвращает избыточные регенерации, но может не поймать все граничные случаи.

## Проблемы Middleware

### Middleware не выполняется

**Симптомы:** Interceptors middleware не вызываются.

**Решения:**
1. Убедитесь, что middleware добавлен в правильный список:
```dart
requestInterceptors: [/* request middleware */],
responseInterceptors: [/* response middleware */],
```

2. Проверьте, что middleware реализует правильный интерфейс:
```dart
class MyMiddleware implements RequestInterceptor {
  @override
  Future<HttpRequest> onRequest(HttpRequest request) async {
    // Реализация
  }
}
```

### Ретраи не работают

**Симптомы:** Запросы не повторяются при ошибках.

**Решения:**
1. Убедитесь, что `RetryInterceptor` в `responseInterceptors`:
```dart
responseInterceptors: [
  RetryInterceptor(maxRetries: 3),
],
```

2. Проверьте, что ошибка в `retryableStatusCodes` или `retryableErrors`
3. Убедитесь, что `maxRetries` больше 0

### Circuit breaker всегда открыт

**Симптомы:** Circuit breaker блокирует все запросы.

**Решения:**
1. Проверьте, что `failureThreshold` не слишком низкий
2. Убедитесь, что `resetTimeout` позволяет circuit восстановиться
3. Проверьте состояние circuit breaker:
```dart
print('Circuit state: ${circuitBreaker.state}');
print('Failure count: ${circuitBreaker.failureCount}');
```

## Проблемы CI/CD

### Workflow не запускается

**Симптомы:** GitHub Actions workflow не выполняется.

**Решения:**
1. Проверьте, что workflow файл в `.github/workflows/`
2. Убедитесь, что `paths` соответствуют расположению вашего spec файла:
```yaml
on:
  push:
    paths:
      - 'swagger/**'  # Настройте под вашу структуру
```

3. Убедитесь, что workflow файл имеет правильный синтаксис YAML

### Ошибки прав доступа

**Симптомы:** Workflow завершается ошибками прав доступа.

**Решения:**
1. Проверьте настройки репозитория → Actions → General
2. Включите "Read and write permissions" для workflows
3. Убедитесь, что `GITHUB_TOKEN` имеет необходимые права

### Изменения не коммитятся

**Симптомы:** Workflow выполняется, но не коммитит изменения.

**Решения:**
1. Убедитесь, что git user настроен:
```yaml
git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
```

2. Проверьте, что workflow имеет права на запись
3. Убедитесь, что файлы действительно генерируются

## Получение дополнительной помощи

1. Проверьте [FAQ](doc/ru/FAQ.md) для частых вопросов
2. См. [Руководство по использованию](doc/ru/USAGE.md) для подробной документации
3. Изучите [Руководство для разработчиков](doc/ru/DEVELOPERS.md) для деталей реализации
4. Откройте issue на [GitHub](https://github.com/AlexGalitsky/dart_swagger_to_api_client/issues) с:
   - OpenAPI спецификацией (если возможно)
   - Сообщениями об ошибках
   - Шагами для воспроизведения
   - Ожидаемым vs фактическим поведением
