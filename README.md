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

На v0.1 пакет находится на ранней стадии и генерирует один файл
`api_client.dart` с минимальным `ApiClient` и `DefaultApi`. Поддерживаются
простейшие `GET`‑эндпоинты без path‑параметров и с `operationId`.

Установите пакет как dev‑dependency в своём проекте и подготовьте
OpenAPI/Swagger‑спеку (`api.yaml` или `api.json`).

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

final client = ApiClient(config);

// Если в спецификации есть GET-эндпоинт с operationId `getUser`,
// будет сгенерирован метод:
//
//   Future<Map<String, dynamic>> getUser()
//
// Вызов:
final userJson = await client.defaultApi.getUser();
```

На этом этапе все методы возвращают `Map<String, dynamic>` — привязка к
конкретным моделям (`User`, `Order` и т.д.) появится на следующих итерациях.

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
