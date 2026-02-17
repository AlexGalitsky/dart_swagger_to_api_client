<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

`dart_swagger_to_api_client` — экспериментальный генератор HTTP‑клиента поверх
OpenAPI/Swagger‑спецификаций и моделей, сгенерированных пакетом
`dart_swagger_to_models`.

## Getting started

`dart_swagger_to_api_client` — генератор типобезопасного HTTP‑клиента из OpenAPI/Swagger спецификаций.
Пакет работает в связке с `dart_swagger_to_models` для генерации полного стека: модели + API клиент.

### Быстрый старт (End-to-End)

Полный сценарий использования от спецификации до вызова API:

#### 1. Установка зависимостей

Добавьте пакеты в `pubspec.yaml`:

```yaml
dev_dependencies:
  dart_swagger_to_models: ^0.9.0
  dart_swagger_to_api_client: ^1.0.0
```

#### 2. Генерация моделей

Сначала сгенерируйте модели из OpenAPI спецификации:

```bash
dart run dart_swagger_to_models:dart_swagger_to_models \
  --input swagger/api.yaml \
  --output-dir lib/models \
  --style json_serializable
```

Это создаст модели (например, `User`, `Order`) в директории `lib/models/`.

#### 3. Генерация API клиента

Затем сгенерируйте API клиент:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

Генератор автоматически обнаружит сгенерированные модели и создаст типобезопасные методы.

#### 4. Использование в коде

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
  // Типобезопасный вызов API
  final List<User> users = await client.defaultApi.getUsers();
  print('Users: $users');
} finally {
  await client.close();
}
```

### Расширенные примеры

См. директорию `example/` для полных примеров:
- `complete_example.dart` — полный end-to-end пример
- `auth_example.dart` — различные методы аутентификации
- `error_handling_example.dart` — обработка ошибок и retry логика

## CLI usage

Запустите генератор в своём проекте:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

### CLI опции

- `--input` / `-i`: Путь к OpenAPI/Swagger спецификации (YAML или JSON). Обязательный.
- `--output-dir`: Директория, куда будет сгенерирован код. Обязательный.
- `--config` / `-c`: Путь к файлу конфигурации `dart_swagger_to_api_client.yaml` (опционально).
- `--verbose` / `-v`: Показывать подробный вывод, включая предупреждения валидации.
- `--quiet` / `-q`: Показывать только ошибки, скрывать предупреждения.
- `--env`: Выбрать профиль окружения из конфигурационного файла (например, `dev`, `staging`, `prod`).
- `--watch` / `-w`: Автоматически регенерировать клиент при изменении спецификации или конфигурационного файла.
- `--help` / `-h`: Показать справку по использованию.

### Валидация спецификации

Генератор автоматически валидирует OpenAPI-спецификацию перед генерацией кода:

- **Ошибки** (errors): блокируют генерацию. Например, отсутствие секции `paths`.
- **Предупреждения** (warnings): не блокируют генерацию, но указывают на потенциальные проблемы:
  - Отсутствие `operationId` у операций (такие операции будут пропущены)
  - Неподдерживаемые типы контента в `requestBody` (только `application/json`)
  - Неподдерживаемые локации параметров (только `path` и `query`)

Предупреждения выводятся при использовании флага `--verbose` или по умолчанию (если не указан `--quiet`).

### Профили окружений

Вы можете определить несколько профилей окружений в конфигурационном файле:

```yaml
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

Затем используйте флаг `--env` для выбора профиля:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

### Bearer Token из переменных окружения

Вы можете указать переменную окружения для bearer token вместо прямого значения:

```yaml
client:
  auth:
    bearerTokenEnv: API_BEARER_TOKEN  # Читается из переменной окружения
```

Токен будет автоматически читаться из переменной окружения во время выполнения.

После этого в директории `lib/api_client` появится файл `api_client.dart`
со следующим паттерном:

```dart
import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

// Использование стандартного HTTP адаптера (package:http)
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
);

// Или использование Dio адаптера
import 'package:dio/dio.dart';
final dio = Dio();
final adapter = DioHttpClientAdapter(dio: dio);
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  httpClientAdapter: adapter,
);

// Или использование кастомного адаптера
// (см. раздел "Using Custom Adapters" ниже)

final client = ApiClient(config);

// Если в спецификации есть GET-эндпоинт с operationId `getUser`,
// будет сгенерирован метод:
//
//   Future<Map<String, dynamic>> getUser()
//
// Вызов:
final userJson = await client.defaultApi.getUser();
```

> **Примечание**: Если вы используете `dart_swagger_to_models` для генерации моделей,
> методы будут возвращать типобезопасные модели вместо `Map<String, dynamic>`.

### Управление ресурсами и scoped клиенты

#### Закрытие клиента

Когда клиент больше не нужен, вызовите `close()` для освобождения ресурсов:

```dart
final client = ApiClient(config);
try {
  // Использование клиента
  await client.defaultApi.getUsers();
} finally {
  await client.close(); // Освобождает ресурсы адаптера
}
```

#### Scoped клиенты с дополнительными заголовками

Метод `withHeaders()` создаёт новый клиент с объединёнными заголовками:

```dart
final baseClient = ApiClient(config);

// Создать scoped клиент с дополнительными заголовками
final scopedClient = baseClient.withHeaders({
  'X-Request-ID': '123',
  'X-User-ID': 'user-456',
});

// Все запросы через scopedClient будут включать эти заголовки
final users = await scopedClient.defaultApi.getUsers();
```

Заголовки из `withHeaders()` переопределяют существующие заголовки с тем же ключом.

### Watch-режим

Вы можете автоматически регенерировать клиент при изменении спецификации или конфигурационного файла с помощью флага `--watch`:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --watch
```

**Поведение:**

- Один запуск генерации на старте
- Наблюдение за файлом спецификации и автоматическая регенерация клиента при сохранении (с debounce 500ms)
- Если указан `--config`, также отслеживаются изменения в конфигурационном файле
- При изменении конфигурационного файла он автоматически перезагружается
- Учитываются остальные флаги: `--env`, `--verbose`, `--quiet`

> **Важно:** Watch-режим поддерживается только для локальных файлов, переданных в `--input`. URL (`http://...` / `https://...`) в watch-режиме использовать нельзя.

Для остановки watch-режима нажмите `Ctrl+C`.

## v0.1 Smoke test (в этом репозитории)

В репозитории есть минимальная OpenAPI‑спека для теста:

- `example/swagger/api.yaml` — определяет эндпоинт `GET /users` с `operationId: getUsers`.

Для ручной проверки генератора можно:

1. Из корня репозитория выполнить:

   ```bash
   dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
     --input example/swagger/api.yaml \
     --output-dir example/generated
   ```

2. Убедиться, что в `example/generated/api_client.dart` появился код с классами
   `ApiClient` и `DefaultApi`, а внутри `DefaultApi` есть метод:

   ```dart
   Future<Map<String, dynamic>> getUsers() async { ... }
   ```

Дальше этот файл можно скопировать в любой проект и использовать так, как
показано в секции CLI usage.
