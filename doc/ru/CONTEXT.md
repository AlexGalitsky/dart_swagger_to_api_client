# Контекст для LLM — dart_swagger_to_api_client

Этот файл оптимизирован для нейросетевых / LLM инструментов для быстрого восстановления контекста проекта.

## Что делает этот проект

- **CLI инструмент**, который **генерирует типобезопасные HTTP API клиенты** из **OpenAPI/Swagger (2.0 / 3.x)** спецификаций
- **Вход**: OpenAPI/Swagger спецификация (YAML/JSON файл)
- **Выход**: Сгенерированный Dart код с классом `ApiClient` и методами эндпоинтов
- **Работает с**: `dart_swagger_to_models` для полного стека (модели + клиент)
- **Ключевая функция**: Типобезопасные API вызовы с автоматической интеграцией моделей

## Основная архитектура

### Структура пакета

```
lib/
├── dart_swagger_to_api_client.dart      # Публичный API фасад
└── src/
    ├── config/                          # Конфигурация
    │   ├── config.dart                  # ApiClientConfig, AuthConfig
    │   └── config_loader.dart           # Загрузчик YAML конфигурации
    ├── core/                            # Основная функциональность
    │   ├── client_generator.dart        # Главный оркестратор
    │   ├── spec_loader.dart             # Загрузчик OpenAPI спецификации
    │   ├── spec_validator.dart          # Валидация спецификации
    │   ├── http_client_adapter.dart     # HTTP абстракция
    │   ├── dio_http_client_adapter.dart # Адаптер Dio
    │   ├── errors.dart                  # Типы исключений
    │   ├── middleware.dart              # Интерфейсы middleware
    │   └── middleware/                  # Реализации middleware
    ├── generators/                      # Генераторы кода
    │   ├── api_client_class_generator.dart
    │   └── endpoint_method_generator.dart
    └── models/                          # Интеграция с моделями
        ├── models_resolver.dart
        ├── models_config.dart
        ├── models_config_loader.dart
        └── file_based_models_resolver.dart
```

### Ключевые компоненты

1. **`ApiClientGenerator`** (`lib/src/core/client_generator.dart`)
   - Точка входа: `ApiClientGenerator.generateClient()`
   - Оркестрирует: загрузка спецификации → валидация → разрешение моделей → генерация кода
   - Возвращает: Сгенерированный файл `api_client.dart`

2. **`SpecLoader`** (`lib/src/core/spec_loader.dart`)
   - Загружает YAML/JSON OpenAPI спецификации
   - Возвращает `Map<String, dynamic>`

3. **`SpecValidator`** (`lib/src/core/spec_validator.dart`)
   - Валидирует структуру спецификации
   - Проверяет наличие `paths`, `operationId`
   - Сообщает предупреждения о неподдерживаемых функциях
   - Возвращает `List<ValidationIssue>`

4. **`EndpointMethodGenerator`** (`lib/src/generators/endpoint_method_generator.dart`)
   - Парсит OpenAPI `paths` и `operations`
   - Генерирует сигнатуры методов с параметрами (path, query, header, cookie)
   - Обрабатывает request bodies (JSON, form-urlencoded, multipart, text/plain, text/html, XML)
   - Классифицирует типы ответов (void, Map, List, Model)
   - Использует `ModelsResolver` для разрешения `$ref` в Dart типы
   - Возвращает: `({String methods, Set<String> imports})`

5. **`ApiClientClassGenerator`** (`lib/src/generators/api_client_class_generator.dart`)
   - Генерирует класс `ApiClient` с геттером `defaultApi`
   - Генерирует класс `DefaultApi` с методами эндпоинтов
   - Добавляет методы `close()` и `withHeaders()`
   - Включает импорты моделей

6. **`HttpClientAdapter`** (`lib/src/core/http_client_adapter.dart`)
   - Абстрактный интерфейс для HTTP реализаций
   - Реализации: `HttpHttpClientAdapter` (http), `DioHttpClientAdapter` (dio)
   - Модели: `HttpRequest`, `HttpResponse`

7. **Система middleware** (`lib/src/core/middleware.dart`)
   - `RequestInterceptor`: Модифицировать запросы перед отправкой
   - `ResponseInterceptor`: Обрабатывать ответы и ошибки
   - `MiddlewareHttpClientAdapter`: Цепочка middleware
   - Встроенные: Logging, Retry, RateLimit, CircuitBreaker, Transformer

8. **Интеграция с моделями** (`lib/src/models/`)
   - `ModelsResolver`: Интерфейс для разрешения `$ref` → Dart типы
   - `FileBasedModelsResolver`: Сканирует сгенерированные файлы моделей
   - `NoOpModelsResolver`: Запасной вариант (возвращает `Map<String, dynamic>`)

## Поток генерации

```
1. Загрузка OpenAPI спецификации (YAML/JSON)
   ↓ SpecLoader.load()
   
2. Валидация спецификации
   ↓ SpecValidator.validate()
   
3. Загрузка конфигурации моделей (если существует)
   ↓ ModelsConfigLoader.load()
   
4. Инициализация резолвера моделей
   ↓ FileBasedModelsResolver или NoOpModelsResolver
   
5. Генерация методов эндпоинтов
   ↓ EndpointMethodGenerator.generateDefaultApiMethods()
   - Парсит paths и operations
   - Разрешает $ref в типы моделей
   - Генерирует сигнатуры методов
   - Классифицирует типы ответов
   
6. Генерация класса ApiClient
   ↓ ApiClientClassGenerator.generate()
   - Создает классы ApiClient и DefaultApi
   - Вставляет методы эндпоинтов
   - Добавляет импорты
   
7. Запись в файл
   ↓ api_client.dart
```

## Ключевые структуры данных

### ApiClientConfig

```dart
class ApiClientConfig {
  final Uri baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final AuthConfig? auth;
  final HttpClientAdapter httpClientAdapter;
  final List<RequestInterceptor> requestInterceptors;
  final List<ResponseInterceptor> responseInterceptors;
}
```

### AuthConfig

```dart
class AuthConfig {
  final String? apiKeyHeader;
  final String? apiKeyQuery;
  final String? apiKey;
  final String? bearerToken;
  final String? bearerTokenEnv;  // Имя переменной окружения
}
```

### HttpRequest / HttpResponse

```dart
class HttpRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Object? body;  // Может быть String, Map, File, List<int>
  final Duration? timeout;
}

class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;
}
```

## Правила генерации

### Генерация методов

- **Operation ID**: Обязателен. Операции без `operationId` пропускаются
- **HTTP методы**: Поддерживает GET, POST, PUT, DELETE, PATCH
- **Параметры**: 
  - `path`: Обязательные параметры в сигнатуре метода
  - `query`: Опциональные параметры
  - `header`: Добавляются в заголовки запроса
  - `cookie`: Добавляются в заголовок Cookie
- **Request Body**:
  - `application/json`: Сериализуется в JSON строку (тип: `Map<String, dynamic>` или модель)
  - `application/x-www-form-urlencoded`: Сериализуется в query строку (тип: `Map<String, String>`)
  - `multipart/form-data`: Обрабатывается как `Map<String, dynamic>` с File/List<int>
  - `text/plain`: Передается как строка (тип: `String`)
  - `text/html`: Передается как строка (тип: `String`)
  - `application/xml`: Передается как строка для простых типов или сериализуется для сложных (тип: `String` или `Map<String, dynamic>`)
  - Поддержка множественных content types с автоматическим выбором по приоритету
- **Типы ответов**:
  - `204 No Content` → `Future<void>`
  - Пустой content → `Future<void>`
  - Object schema → `Future<Map<String, dynamic>>` или `Future<ModelType>`
  - Array schema → `Future<List<Map<String, dynamic>>>` или `Future<List<ModelType>>`

### Разрешение моделей

- Если существует `dart_swagger_to_models.yaml`:
  - `FileBasedModelsResolver` сканирует файлы моделей
  - Маппит имена схем на имена Dart классов
  - Разрешает `$ref` в пути импорта
- Иначе:
  - `NoOpModelsResolver` возвращает `Map<String, dynamic>`

### Классификация типов

```dart
class _ResponseTypeInfo {
  final bool voidResponse;
  final bool mapResponse;
  final bool listResponse;
  final String? modelResponse;
  final String? listModelResponse;
}
```

## Конфигурация

### YAML конфигурационный файл

```yaml
input: swagger/api.yaml
outputDir: lib/api_client

client:
  baseUrl: https://api.example.com
  headers:
    User-Agent: my-app/1.0.0
  timeout: 30000
  auth:
    bearerTokenEnv: API_BEARER_TOKEN

http:
  adapter: http  # или 'dio', 'custom'
  customAdapterType: MyCustomAdapter

environments:
  dev:
    baseUrl: https://dev-api.example.com
  prod:
    baseUrl: https://api.example.com
```

### Аргументы CLI

- `--input` / `-i`: Путь к спецификации (обязательно)
- `--output-dir`: Директория вывода (обязательно)
- `--config` / `-c`: Путь к конфигурационному файлу
- `--env`: Имя профиля окружения
- `--watch` / `-w`: Watch-режим
- `--verbose` / `-v`: Подробный вывод
- `--quiet` / `-q`: Тихий режим

## Система middleware

### Request Interceptors

- Применяются по порядку перед отправкой запроса
- Могут модифицировать: заголовки, URL, тело, таймаут
- Примеры: RateLimit, Logging, Transformer

### Response Interceptors

- Применяются в обратном порядке после получения ответа
- Могут модифицировать: ответ, выбрасывать исключения
- Примеры: Retry, CircuitBreaker, Logging, Transformer

### Обработка ошибок

- Request interceptors могут выбрасывать исключения (обрабатываются response interceptors)
- Response interceptors могут обрабатывать ошибки через метод `onError()`
- RetryInterceptor выбрасывает `RetryableException` для сигнала о ретрае

## Тестирование

### Организация тестов

- `api_client_generator_test.dart`: Полный цикл генерации
- `endpoint_method_generator_test.dart`: Генерация методов
- `spec_validator_test.dart`: Логика валидации
- `config_loader_test.dart`: Загрузка конфигурации
- `http_client_adapter_test.dart`: Тесты HTTP адаптера
- `middleware_*_test.dart`: Тесты middleware
- `integration_test.dart`: End-to-end (опционально)
- `regression_test.dart`: Регрессионные тесты
- `edge_cases_test.dart`: Граничные случаи

### Запуск тестов

```bash
dart test
```

## Частые команды

### Генерация клиента

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

### С конфигурацией

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

### Watch-режим

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --watch
```

## Ключевые архитектурные решения

1. **Разделение от моделей**: Модели и клиент — отдельные пакеты для гибкости
2. **HTTP абстракция**: Подключаемые адаптеры позволяют разные HTTP реализации
3. **Цепочка middleware**: Request/Response interceptors для расширяемости
4. **Слабая связанность**: Резолвер моделей позволяет опциональную интеграцию моделей
5. **Приоритет конфигурации**: CLI > Config > Defaults

## При модификации этого проекта

### Добавление нового HTTP адаптера

1. Реализуйте интерфейс `HttpClientAdapter`
2. Маппируйте типы адаптера на `HttpRequest`/`HttpResponse`
3. Экспортируйте в `lib/dart_swagger_to_api_client.dart`
4. Добавьте тесты
5. Обновите документацию

### Добавление нового middleware

1. Реализуйте `RequestInterceptor` или `ResponseInterceptor`
2. Экспортируйте в публичном API
3. Добавьте тесты
4. Добавьте пример
5. Обновите документацию

### Изменение логики генерации

1. Обновите `EndpointMethodGenerator` или `ApiClientClassGenerator`
2. Обновите тесты чтобы соответствовать новому выводу
3. Протестируйте с различными OpenAPI спецификациями
4. Обновите документацию

### Изменение логики типов ответов

1. Обновите `_classifyResponseType()` в `EndpointMethodGenerator`
2. Обновите класс `_ResponseTypeInfo`
3. Обновите тесты которые проверяют типы возврата
4. Обновите документацию

## Текущий статус

- ✅ v0.1-v0.8 завершены
- ✅ Все основные функции реализованы
- ✅ Комплексный набор тестов (173+ тестов)
- ✅ Полная документация
- ✅ Шаблоны CI/CD
- ✅ Примеры state management

## Связанные файлы

- `API_CLIENT_NOTES.md`: Оригинальный документ дизайна
- `doc/ROADMAP.ru.md`: Дорожная карта разработки
- `README.md`: Пользовательская документация
- `doc/ru/USAGE.md`: Подробное руководство по использованию
- `doc/ru/DEVELOPERS.md`: Руководство для разработчиков
