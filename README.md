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
- `--help` / `-h`: Показать справку по использованию.

### Валидация спецификации

Генератор автоматически валидирует OpenAPI-спецификацию перед генерацией кода:

- **Ошибки** (errors): блокируют генерацию. Например, отсутствие секции `paths`.
- **Предупреждения** (warnings): не блокируют генерацию, но указывают на потенциальные проблемы:
  - Отсутствие `operationId` у операций (такие операции будут пропущены)
  - Неподдерживаемые типы контента в `requestBody` (только `application/json`)
  - Неподдерживаемые локации параметров (только `path` и `query`)

Предупреждения выводятся при использовании флага `--verbose` или по умолчанию (если не указан `--quiet`).

После этого в директории `lib/api_client` появится файл `api_client.dart`
со следующим паттерном:

```dart
import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
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
