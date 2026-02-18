# Руководство для разработчиков

Этот документ описывает структуру проекта и порядок работы с кодовой базой для новых разработчиков.

## Содержание

1. [Структура репозитория](#структура-репозитория)
2. [Обзор архитектуры](#обзор-архитектуры)
3. [Процесс разработки](#процесс-разработки)
4. [Организация кода](#организация-кода)
5. [Тестирование](#тестирование)
6. [Добавление новых функций](#добавление-новых-функций)
7. [Стандарты кодирования](#стандарты-кодирования)
8. [Руководство по участию](#руководство-по-участию)

## Структура репозитория

```
dart_swagger_to_api_client/
├── bin/
│   └── dart_swagger_to_api_client.dart    # Точка входа CLI
├── lib/
│   ├── dart_swagger_to_api_client.dart    # Публичный API фасад
│   └── src/
│       ├── config/                        # Конфигурация
│       │   ├── config.dart                # ApiClientConfig, AuthConfig
│       │   └── config_loader.dart         # Загрузчик YAML конфигурации
│       ├── core/                          # Основная функциональность
│       │   ├── client_generator.dart      # Главный оркестратор генератора
│       │   ├── spec_loader.dart           # Загрузчик OpenAPI спецификации
│       │   ├── spec_validator.dart        # Валидация спецификации
│       │   ├── http_client_adapter.dart   # HTTP абстракция
│       │   ├── dio_http_client_adapter.dart # Адаптер Dio
│       │   ├── errors.dart                # Типы исключений
│       │   ├── middleware.dart            # Интерфейсы middleware
│       │   └── middleware/                 # Реализации middleware
│       │       ├── logging_middleware.dart
│       │       ├── retry_middleware.dart
│       │       ├── rate_limit_middleware.dart
│       │       ├── circuit_breaker_middleware.dart
│       │       └── transformer_middleware.dart
│       ├── generators/                    # Генераторы кода
│       │   ├── api_client_class_generator.dart  # Класс ApiClient
│       │   └── endpoint_method_generator.dart    # Методы эндпоинтов
│       └── models/                        # Интеграция с моделями
│           ├── models_resolver.dart       # Интерфейс резолвера
│           ├── models_config.dart        # DTO конфигурации моделей
│           ├── models_config_loader.dart # Загрузчик конфигурации моделей
│           └── file_based_models_resolver.dart  # Файловый резолвер
├── test/                                  # Тестовые наборы
├── example/                               # Примеры использования
├── doc/                                   # Документация
│   ├── en/                                # Английская документация
│   └── ru/                                # Русская документация
└── ci/                                    # Шаблоны CI/CD
```

## Обзор архитектуры

### Основные компоненты

1. **Загрузка спецификации** (`spec_loader.dart`)
   - Загружает OpenAPI/Swagger спецификации из YAML/JSON файлов
   - Возвращает `Map<String, dynamic>`

2. **Валидация спецификации** (`spec_validator.dart`)
   - Валидирует структуру спецификации
   - Проверяет обязательные поля (`paths`, `operationId`)
   - Сообщает предупреждения о неподдерживаемых функциях
   - Возвращает `List<ValidationIssue>`

3. **Генерация клиента** (`client_generator.dart`)
   - Оркестрирует процесс генерации
   - Загружает конфигурацию моделей и создает резолвер
   - Вызывает генераторы и записывает результат

4. **Генераторы кода**
   - `ApiClientClassGenerator`: Генерирует классы `ApiClient` и `DefaultApi`
   - `EndpointMethodGenerator`: Генерирует методы эндпоинтов

5. **HTTP абстракция** (`http_client_adapter.dart`)
   - Интерфейс `HttpClientAdapter`
   - Модели `HttpRequest` и `HttpResponse`
   - Реализации: `HttpHttpClientAdapter`, `DioHttpClientAdapter`

6. **Система middleware** (`middleware.dart`)
   - Интерфейсы `RequestInterceptor` и `ResponseInterceptor`
   - `MiddlewareHttpClientAdapter` для цепочки middleware
   - Встроенные middleware: логирование, ретраи, rate limiting, circuit breaker, трансформации

7. **Интеграция с моделями** (`models/`)
   - Интерфейс `ModelsResolver` для разрешения `$ref` в Dart типы
   - `FileBasedModelsResolver` сканирует сгенерированные файлы моделей
   - `NoOpModelsResolver` как запасной вариант

### Поток данных

```
OpenAPI Spec (YAML/JSON)
    ↓
SpecLoader.load()
    ↓
SpecValidator.validate()
    ↓
ModelsConfigLoader.load() → ModelsResolver
    ↓
EndpointMethodGenerator.generateDefaultApiMethods()
    ↓
ApiClientClassGenerator.generate()
    ↓
api_client.dart (сгенерированный)
```

## Процесс разработки

### Настройка

1. Клонируйте репозиторий:
```bash
git clone https://github.com/AlexGalitsky/dart_swagger_to_api_client.git
cd dart_swagger_to_api_client
```

2. Установите зависимости:
```bash
dart pub get
```

3. Запустите тесты:
```bash
dart test
```

### Запуск анализа

```bash
dart analyze
```

### Запуск тестов

```bash
# Все тесты
dart test

# Конкретный тестовый файл
dart test test/endpoint_method_generator_test.dart

# С подробным выводом
dart test --reporter=expanded
```

### Тестирование сгенерированного кода

1. Сгенерируйте клиент из примера спецификации:
```bash
dart run bin/dart_swagger_to_api_client.dart \
  --input example/swagger/api.yaml \
  --output-dir example/generated
```

2. Проверьте сгенерированный код:
```bash
cat example/generated/api_client.dart
```

## Организация кода

### Слой конфигурации (`lib/src/config/`)

- **`config.dart`**: Основные классы конфигурации
  - `ApiClientConfig`: Главная конфигурация клиента
  - `AuthConfig`: Настройки аутентификации
  - `EnvironmentProfile`: Конфигурации для окружений

- **`config_loader.dart`**: Загрузчик YAML конфигурации
  - Парсит `dart_swagger_to_api_client.yaml`
  - Объединяет базовую конфигурацию с профилями окружений
  - Обрабатывает переопределения аргументов CLI

### Основной слой (`lib/src/core/`)

- **`client_generator.dart`**: Главный оркестратор
  - Точка входа: `ApiClientGenerator.generateClient()`
  - Координирует загрузку спецификации, валидацию и генерацию
  - Управляет инициализацией резолвера моделей

- **`spec_loader.dart`**: Загрузка файлов спецификации
  - Поддерживает форматы YAML и JSON
  - Обрабатывает пути к файлам и URL (для будущего)

- **`spec_validator.dart`**: Валидация спецификации
  - Валидирует структуру OpenAPI
  - Проверяет обязательные поля
  - Сообщает предупреждения о неподдерживаемых функциях

- **`http_client_adapter.dart`**: HTTP абстракция
  - Интерфейс `HttpClientAdapter`
  - Модели `HttpRequest` и `HttpResponse`
  - Реализация `HttpHttpClientAdapter`

- **`dio_http_client_adapter.dart`**: Адаптер Dio
  - Реализация `DioHttpClientAdapter`
  - Маппинг типов Dio на интерфейс адаптера

- **`errors.dart`**: Типы исключений
  - `ApiClientException`: Базовое исключение
  - `ApiServerException`: Ошибки сервера (5xx)
  - `ApiAuthException`: Ошибки аутентификации (401, 403)
  - `TimeoutException`: Ошибки таймаута

- **`middleware.dart`**: Система middleware
  - Интерфейсы `RequestInterceptor` и `ResponseInterceptor`
  - Реализация `MiddlewareHttpClientAdapter`

### Слой генераторов (`lib/src/generators/`)

- **`api_client_class_generator.dart`**: Генерирует главный класс клиента
  - Класс `ApiClient` с геттером `defaultApi`
  - Класс `DefaultApi` с методами эндпоинтов
  - Методы `close()` и `withHeaders()`

- **`endpoint_method_generator.dart`**: Генерирует методы эндпоинтов
  - Парсит OpenAPI paths и operations
  - Генерирует сигнатуры методов с параметрами
  - Обрабатывает request bodies и responses
  - Интегрируется с резолвером моделей

### Слой моделей (`lib/src/models/`)

- **`models_resolver.dart`**: Интерфейс резолвера
  - Абстрактный класс `ModelsResolver`
  - Запасная реализация `NoOpModelsResolver`

- **`models_config.dart`**: DTO конфигурации моделей
  - `ModelsConfig`: Конфигурация из `dart_swagger_to_models.yaml`
  - `SchemaOverride`: Переопределения для конкретных схем

- **`models_config_loader.dart`**: Загружает конфигурацию моделей
  - Сканирует `dart_swagger_to_models.yaml`
  - Парсит конфигурацию

- **`file_based_models_resolver.dart`**: Файловый резолвер
  - Сканирует сгенерированные файлы моделей
  - Маппит имена схем на имена Dart классов
  - Разрешает `$ref` в пути импорта

## Тестирование

### Структура тестов

Тесты организованы по темам:

- `api_client_generator_test.dart`: Интеграционные тесты для полной генерации
- `endpoint_method_generator_test.dart`: Юнит-тесты для генерации методов
- `spec_validator_test.dart`: Тесты валидации
- `config_loader_test.dart`: Тесты загрузки конфигурации
- `http_client_adapter_test.dart`: Тесты HTTP адаптера
- `middleware_*_test.dart`: Тесты middleware
- `integration_test.dart`: End-to-end тесты (опционально, требует интернет)
- `regression_test.dart`: Регрессионные тесты
- `edge_cases_test.dart`: Тесты граничных случаев

### Запуск тестов

```bash
# Все тесты
dart test

# Конкретный набор
dart test test/endpoint_method_generator_test.dart

# С покрытием (требует пакет coverage)
dart test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

### Написание тестов

1. Следуйте существующим паттернам тестов
2. Используйте описательные имена тестов
3. Тестируйте как успешные, так и ошибочные случаи
4. Мокируйте внешние зависимости когда возможно
5. Используйте `setUp` и `tearDown` для общей настройки

Пример:

```dart
test('генерирует GET метод с path параметрами', () async {
  final generator = EndpointMethodGenerator();
  final spec = {
    'paths': {
      '/users/{id}': {
        'get': {
          'operationId': 'getUser',
          'parameters': [
            {'name': 'id', 'in': 'path', 'required': true, 'schema': {'type': 'string'}},
          ],
          'responses': {'200': {'description': 'OK'}},
        },
      },
    },
  };

  final result = await generator.generateDefaultApiMethods(spec);
  
  expect(result.methods, contains('getUser'));
  expect(result.methods, contains('required String id'));
});
```

## Добавление новых функций

### Пошаговый процесс

1. **Спланируйте функцию**
   - Проверьте `doc/ROADMAP.ru.md` на запланированные функции
   - Создайте issue или обсудите в PR
   - Спроектируйте API и архитектуру

2. **Реализуйте функцию**
   - Создайте feature branch
   - Напишите код следуя стандартам кодирования
   - Добавьте тесты
   - Обновите документацию

3. **Тщательно протестируйте**
   - Запустите все существующие тесты
   - Добавьте новые тесты для функции
   - Протестируйте граничные случаи

4. **Обновите документацию**
   - Обновите README если нужно
   - Добавьте примеры использования
   - Обновите USAGE.md
   - Обновите CONTEXT.md если архитектура изменилась

5. **Отправьте PR**
   - Напишите четкое описание PR
   - Ссылайтесь на связанные issues
   - Убедитесь, что CI проходит

### Пример: Добавление нового middleware

1. Создайте файл middleware:
```dart
// lib/src/core/middleware/my_middleware.dart
class MyMiddleware implements RequestInterceptor {
  @override
  Future<HttpRequest> onRequest(HttpRequest request) async {
    // Реализация
  }
}
```

2. Экспортируйте в публичном API:
```dart
// lib/dart_swagger_to_api_client.dart
export 'src/core/middleware/my_middleware.dart';
```

3. Добавьте тесты:
```dart
// test/my_middleware_test.dart
test('MyMiddleware правильно модифицирует запросы', () {
  // Реализация теста
});
```

4. Добавьте в master test file:
```dart
// test/dart_swagger_to_api_client_test.dart
import 'my_middleware_test.dart' as my_middleware_test;
// ...
my_middleware_test.main();
```

5. Добавьте пример:
```dart
// example/my_middleware_example.dart
// Пример использования
```

## Стандарты кодирования

### Стиль кода

- Следуйте руководству [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Используйте `dart format` перед коммитом
- Следуйте существующим паттернам кода

### Соглашения об именовании

- Классы: `PascalCase` (например, `ApiClientConfig`)
- Методы/функции: `camelCase` (например, `generateClient`)
- Приватные члены: `_leadingUnderscore` (например, `_modelsResolver`)
- Константы: `lowerCamelCase` или `SCREAMING_SNAKE_CASE` (например, `maxRetries`)

### Документация

- Документируйте все публичные API
- Используйте комментарии DartDoc (`///`)
- Включайте примеры в документацию
- Документируйте параметры и возвращаемые значения

### Обработка ошибок

- Используйте специфичные типы исключений (`ApiClientException`, `ApiServerException`)
- Предоставляйте понятные сообщения об ошибках
- Включайте контекст в сообщения об ошибках

### Тестирование

- Стремитесь к высокому покрытию тестами
- Тестируйте как успешные, так и ошибочные пути
- Используйте описательные имена тестов
- Группируйте связанные тесты

## Руководство по участию

### Перед участием

1. Проверьте существующие issues и PRs
2. Обсудите крупные изменения в issue сначала
3. Следуйте стандартам кодирования
4. Напишите тесты для новых функций

### Процесс Pull Request

1. Форкните репозиторий
2. Создайте feature branch
3. Внесите изменения
4. Добавьте тесты
5. Обновите документацию
6. Запустите тесты и анализ
7. Отправьте PR с четким описанием

### Сообщения коммитов

Следуйте conventional commits:

```
feat: добавить circuit breaker middleware
fix: исправить обработку таймаутов в HttpHttpClientAdapter
docs: обновить README с новыми функциями
test: добавить тесты для rate limiting
refactor: упростить генерацию методов эндпоинтов
```

### Code Review

- Будьте уважительными и конструктивными
- Проверяйте на корректность, стиль и тесты
- Предлагайте улучшения
- Одобряйте когда удовлетворены

## Ключевые архитектурные решения

### Разделение ответственности

- **Модели** (`dart_swagger_to_models`) и **Клиент** (`dart_swagger_to_api_client`) — отдельные пакеты
- Резолвер моделей позволяет слабую связанность
- HTTP абстракция позволяет подключаемые реализации

### Система middleware

- Request/Response interceptors для гибкости
- Паттерн цепочки ответственности
- Встроенные middleware для общих случаев использования

### Конфигурация

- YAML конфигурационные файлы для декларативной настройки
- Профили окружений для разных развертываний
- Аргументы CLI переопределяют значения конфигурации

### Обработка ошибок

- Специфичные типы исключений для разных категорий ошибок
- Понятные сообщения об ошибках с контекстом
- Правильное распространение исключений

## Частые задачи

### Добавление нового HTTP адаптера

1. Реализуйте интерфейс `HttpClientAdapter`
2. Маппируйте специфичные для адаптера типы на `HttpRequest`/`HttpResponse`
3. Экспортируйте в публичном API
4. Добавьте тесты
5. Обновите документацию

### Добавление нового middleware

1. Реализуйте `RequestInterceptor` или `ResponseInterceptor`
2. Экспортируйте в публичном API
3. Добавьте тесты
4. Добавьте пример
5. Обновите документацию

### Изменение формата сгенерированного кода

1. Обновите `ApiClientClassGenerator` или `EndpointMethodGenerator`
2. Обновите тесты чтобы соответствовать новому формату
3. Протестируйте с различными OpenAPI спецификациями
4. Обновите документацию

## Ресурсы

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Testing in Dart](https://dart.dev/guides/testing)
