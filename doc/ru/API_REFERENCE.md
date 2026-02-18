# Справочник API

Полный справочник API для пакета `dart_swagger_to_api_client`.

## Содержание

1. [Основные классы](#основные-классы)
2. [Конфигурация](#конфигурация)
3. [HTTP адаптеры](#http-адаптеры)
4. [Middleware](#middleware)
5. [Обработка ошибок](#обработка-ошибок)
6. [Генерация кода](#генерация-кода)

## Основные классы

### ApiClientGenerator

Главный класс для генерации API клиентов из OpenAPI/Swagger спецификаций.

#### Методы

##### `generateClient`

```dart
static Future<void> generateClient({
  required String inputSpecPath,
  required String outputDir,
  ApiClientConfig? config,
  String? projectDir,
  void Function(String message)? onWarning,
  String? customAdapterType,
  bool enableCache = true,
})
```

Генерирует Dart файлы API клиента в указанную директорию вывода.

**Параметры:**
- `inputSpecPath` (обязательно): Путь к OpenAPI/Swagger спецификации (YAML или JSON)
- `outputDir` (обязательно): Директория, куда будет записан код клиента
- `config`: Опциональная runtime конфигурация (base URL, auth, HTTP adapter hints)
- `projectDir`: Корневая директория проекта для разрешения относительных путей
- `onWarning`: Опциональный callback для предупреждений
- `customAdapterType`: Опциональное имя типа кастомного адаптера
- `enableCache`: Включить ли кэширование парсинга спецификации (по умолчанию: `true`)

**Выбрасывает:**
- `GenerationException`: Если загрузка спецификации, валидация или генерация кода не удалась
- `ConfigValidationException`: Если валидация конфигурации не удалась

**Пример:**
```dart
await ApiClientGenerator.generateClient(
  inputSpecPath: 'swagger/api.yaml',
  outputDir: 'lib/api_client',
  projectDir: '.',
  onWarning: (msg) => print('Предупреждение: $msg'),
);
```

## Конфигурация

### ApiClientConfig

Runtime конфигурация для сгенерированного API клиента.

```dart
class ApiClientConfig {
  final Uri baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final AuthConfig? auth;
  final HttpClientAdapter httpClientAdapter;
  final List<RequestInterceptor> requestInterceptors;
  final List<ResponseInterceptor> responseInterceptors;

  ApiClientConfig({
    required this.baseUrl,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 30),
    this.auth,
    HttpClientAdapter? httpClientAdapter,
    List<RequestInterceptor>? requestInterceptors,
    List<ResponseInterceptor>? responseInterceptors,
  });
}
```

**Свойства:**
- `baseUrl`: Базовый URL для всех API запросов
- `defaultHeaders`: Заголовки по умолчанию для включения во все запросы
- `timeout`: Длительность таймаута запроса (по умолчанию: 30 секунд)
- `auth`: Конфигурация аутентификации
- `httpClientAdapter`: Реализация HTTP клиент адаптера
- `requestInterceptors`: Список request interceptors
- `responseInterceptors`: Список response interceptors

**Пример:**
```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  defaultHeaders: {'User-Agent': 'my-app/1.0.0'},
  timeout: Duration(seconds: 60),
  auth: AuthConfig(bearerToken: 'token'),
);
```

### AuthConfig

Конфигурация аутентификации.

```dart
class AuthConfig {
  final String? apiKeyHeader;
  final String? apiKeyQuery;
  final String? apiKey;
  final String? bearerToken;
  final String? bearerTokenEnv;

  AuthConfig({
    this.apiKeyHeader,
    this.apiKeyQuery,
    this.apiKey,
    this.bearerToken,
    this.bearerTokenEnv,
  });

  String? resolveBearerToken();
}
```

**Свойства:**
- `apiKeyHeader`: Имя заголовка для аутентификации по API ключу
- `apiKeyQuery`: Имя query параметра для аутентификации по API ключу
- `apiKey`: Значение API ключа
- `bearerToken`: Значение bearer токена
- `bearerTokenEnv`: Имя переменной окружения для bearer токена

**Методы:**
- `resolveBearerToken()`: Возвращает bearer токен из `bearerToken` или `bearerTokenEnv`

**Пример:**
```dart
final auth = AuthConfig(
  bearerTokenEnv: 'API_TOKEN', // Читает из окружения
);
```

### ApiGeneratorConfig

Конфигурация генератора, загружаемая из YAML файла.

```dart
class ApiGeneratorConfig {
  final String? input;
  final String? outputDir;
  final Uri? baseUrl;
  final Map<String, String> headers;
  final AuthConfig? auth;
  final String? httpAdapter;
  final String? customAdapterType;
  final Map<String, EnvironmentProfile> environments;
}
```

**Свойства:**
- `input`: Путь к OpenAPI/Swagger спецификации
- `outputDir`: Директория вывода для сгенерированного кода
- `baseUrl`: Базовый URL по умолчанию
- `headers`: Заголовки по умолчанию
- `auth`: Настройки аутентификации
- `httpAdapter`: Имя HTTP адаптера (`http`, `dio`, `custom`)
- `customAdapterType`: Имя типа кастомного адаптера
- `environments`: Профили окружений

### EnvironmentProfile

Профиль конфигурации для конкретного окружения.

```dart
class EnvironmentProfile {
  final Uri? baseUrl;
  final Map<String, String> headers;
  final AuthConfig? auth;
}
```

## HTTP адаптеры

### HttpClientAdapter

Абстрактный интерфейс для реализаций HTTP клиента.

```dart
abstract class HttpClientAdapter {
  Future<HttpResponse> send(HttpRequest request);
  Future<void> close();
}
```

**Методы:**
- `send(request)`: Отправляет HTTP запрос и возвращает ответ
- `close()`: Закрывает адаптер и освобождает ресурсы

### HttpRequest

Представляет HTTP запрос.

```dart
class HttpRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Object? body;
  final Duration? timeout;

  HttpRequest({
    required this.method,
    required this.url,
    this.headers = const {},
    this.body,
    this.timeout,
  });
}
```

**Свойства:**
- `method`: HTTP метод (GET, POST, PUT, DELETE, PATCH)
- `url`: URL запроса
- `headers`: Заголовки запроса
- `body`: Тело запроса (String, Map, File, List<int>)
- `timeout`: Таймаут запроса

### HttpResponse

Представляет HTTP ответ.

```dart
class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;

  HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });
}
```

**Свойства:**
- `statusCode`: HTTP статус код
- `headers`: Заголовки ответа
- `body`: Тело ответа

### HttpHttpClientAdapter

HTTP адаптер по умолчанию, использующий `package:http`.

```dart
class HttpHttpClientAdapter implements HttpClientAdapter {
  HttpHttpClientAdapter({http.Client? client});

  @override
  Future<HttpResponse> send(HttpRequest request);

  @override
  Future<void> close();
}
```

### DioHttpClientAdapter

HTTP адаптер, использующий `package:dio`.

```dart
class DioHttpClientAdapter implements HttpClientAdapter {
  DioHttpClientAdapter({
    required Dio dio,
    bool ownsDio = false,
  });

  @override
  Future<HttpResponse> send(HttpRequest request);

  @override
  Future<void> close();
}
```

**Параметры:**
- `dio`: Экземпляр Dio для использования
- `ownsDio`: Владеет ли этот адаптер экземпляром Dio (для очистки)

## Middleware

### RequestInterceptor

Интерфейс для перехвата и модификации запросов.

```dart
abstract class RequestInterceptor {
  Future<HttpRequest> onRequest(HttpRequest request);
}
```

**Методы:**
- `onRequest(request)`: Модифицирует запрос перед отправкой

### ResponseInterceptor

Интерфейс для перехвата и обработки ответов.

```dart
abstract class ResponseInterceptor {
  Future<HttpResponse> onResponse(HttpResponse response);
  Future<void> onError(Object error, StackTrace stackTrace);
}
```

**Методы:**
- `onResponse(response)`: Обрабатывает ответ после получения
- `onError(error, stackTrace)`: Обрабатывает ошибки

### LoggingInterceptor

Логирует HTTP запросы и ответы.

```dart
class LoggingInterceptor implements RequestInterceptor, ResponseInterceptor {
  LoggingInterceptor.console({
    bool logHeaders = false,
    bool logBody = false,
  });

  @override
  Future<HttpRequest> onRequest(HttpRequest request);

  @override
  Future<HttpResponse> onResponse(HttpResponse response);

  @override
  Future<void> onError(Object error, StackTrace stackTrace);
}
```

### RetryInterceptor

Повторяет неудачные запросы с экспоненциальным backoff.

```dart
class RetryInterceptor implements ResponseInterceptor {
  RetryInterceptor({
    int maxRetries = 3,
    Set<int> retryableStatusCodes = const {500, 502, 503, 504},
    Set<Type> retryableErrors = const {TimeoutException},
    int baseDelayMs = 1000,
    int maxDelayMs = 10000,
  });

  @override
  Future<HttpResponse> onResponse(HttpResponse response);

  @override
  Future<void> onError(Object error, StackTrace stackTrace);
}
```

**Свойства:**
- `maxRetries`: Максимальное количество попыток повтора
- `retryableStatusCodes`: HTTP статус коды, которые вызывают повтор
- `retryableErrors`: Типы исключений, которые вызывают повтор
- `baseDelayMs`: Базовая задержка в миллисекундах
- `maxDelayMs`: Максимальная задержка в миллисекундах

### RateLimitInterceptor

Ограничивает частоту запросов.

```dart
class RateLimitInterceptor implements RequestInterceptor {
  RateLimitInterceptor({
    required int maxRequests,
    required Duration window,
  });

  @override
  Future<HttpRequest> onRequest(HttpRequest request);
}
```

**Свойства:**
- `maxRequests`: Максимальное количество разрешенных запросов
- `window`: Временное окно для ограничения частоты

### CircuitBreakerInterceptor

Реализует паттерн circuit breaker.

```dart
class CircuitBreakerInterceptor implements RequestInterceptor, ResponseInterceptor {
  CircuitBreakerInterceptor({
    int failureThreshold = 5,
    Duration timeout = const Duration(seconds: 60),
    Duration resetTimeout = const Duration(seconds: 30),
  });

  @override
  Future<HttpRequest> onRequest(HttpRequest request);

  @override
  Future<HttpResponse> onResponse(HttpResponse response);

  @override
  Future<void> onError(Object error, StackTrace stackTrace);
}
```

**Свойства:**
- `failureThreshold`: Количество ошибок перед открытием circuit
- `timeout`: Таймаут для запросов
- `resetTimeout`: Время ожидания перед попыткой закрыть circuit

### TransformerInterceptor

Применяет кастомные трансформации к запросам и ответам.

```dart
class TransformerInterceptor implements RequestInterceptor, ResponseInterceptor {
  TransformerInterceptor({
    RequestTransformer? requestTransformer,
    ResponseTransformer? responseTransformer,
  });

  @override
  Future<HttpRequest> onRequest(HttpRequest request);

  @override
  Future<HttpResponse> onResponse(HttpResponse response);

  @override
  Future<void> onError(Object error, StackTrace stackTrace);
}
```

### RequestTransformers

Вспомогательный класс для общих трансформаций запросов.

```dart
class RequestTransformers {
  static RequestTransformer addHeaders(Map<String, String> headers);
  static RequestTransformer modifyUrl(Uri Function(Uri) transformer);
  static RequestTransformer transformBody(Object? Function(Object?) transformer);
}
```

### ResponseTransformers

Вспомогательный класс для общих трансформаций ответов.

```dart
class ResponseTransformers {
  static ResponseTransformer modifyHeaders(Map<String, String> Function(Map<String, String>) transformer);
  static ResponseTransformer transformBody(String Function(String) transformer);
  static ResponseTransformer normalizeStatusCodes(Map<int, int> statusCodeMap);
}
```

## Обработка ошибок

### ApiClientException

Базовое исключение для всех ошибок API клиента.

```dart
class ApiClientException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? context;
  final Object? cause;

  ApiClientException(
    this.message, {
    this.statusCode,
    this.context,
    this.cause,
  });

  @override
  String toString();
}
```

### ApiServerException

Представляет 5xx HTTP ошибки.

```dart
class ApiServerException extends ApiClientException {
  ApiServerException(
    super.message, {
    super.statusCode,
    super.context,
    super.cause,
  });
}
```

### ApiAuthException

Представляет ошибки аутентификации/авторизации (401/403).

```dart
class ApiAuthException extends ApiClientException {
  ApiAuthException(
    super.message, {
    super.statusCode,
    super.context,
    super.cause,
  });
}
```

### TimeoutException

Представляет ошибки таймаута.

```dart
class TimeoutException extends ApiClientException {
  TimeoutException(
    super.message,
    Duration timeout, {
    Map<String, dynamic>? context,
    super.cause,
  });
}
```

### GenerationException

Представляет ошибки во время генерации кода.

```dart
class GenerationException implements Exception {
  final String message;
  final String? path;
  final Map<String, dynamic>? context;
  final Object? cause;

  GenerationException(
    this.message, {
    this.path,
    this.context,
    this.cause,
  });

  @override
  String toString();
}
```

### ConfigValidationException

Представляет ошибки валидации конфигурации.

```dart
class ConfigValidationException implements Exception {
  final String message;
  final String? field;
  final Map<String, dynamic>? context;
  final Object? cause;

  ConfigValidationException(
    this.message, {
    this.field,
    this.context,
    this.cause,
  });

  @override
  String toString();
}
```

### CircuitBreakerOpenException

Выбрасывается, когда circuit breaker открыт.

```dart
class CircuitBreakerOpenException extends ApiClientException {
  CircuitBreakerOpenException(String message);
}
```

## Генерация кода

### SpecLoader

Загружает OpenAPI/Swagger спецификации из файлов.

```dart
class SpecLoader {
  SpecLoader({SpecCache? cache});

  Future<Map<String, dynamic>> load(String inputPath);
}
```

**Методы:**
- `load(inputPath)`: Загружает и парсит файл спецификации (YAML или JSON)

### SpecValidator

Валидирует OpenAPI/Swagger спецификации.

```dart
class SpecValidator {
  static List<SpecIssue> validate(Map<String, dynamic> spec);
}
```

**Методы:**
- `validate(spec)`: Валидирует спецификацию и возвращает список проблем

### SpecIssue

Представляет проблему валидации.

```dart
class SpecIssue {
  final IssueSeverity severity;
  final String message;
  final String path;

  SpecIssue({
    required this.severity,
    required this.message,
    required this.path,
  });
}
```

### IssueSeverity

Серьезность проблемы валидации.

```dart
enum IssueSeverity {
  error,
  warning,
}
```

### SpecCache

Кэширует распарсенные OpenAPI спецификации.

```dart
class SpecCache {
  SpecCache({required String cacheDir});

  Future<Map<String, dynamic>?> getCachedSpec(String specPath);
  Future<void> cacheSpec(String specPath, Map<String, dynamic> spec);
  Future<void> clear();
}
```

### ConfigValidator

Валидирует конфигурацию генератора.

```dart
class ConfigValidator {
  static void validate(ApiGeneratorConfig config);
}
```

**Методы:**
- `validate(config)`: Валидирует конфигурацию и выбрасывает `ConfigValidationException` при неудаче

### ModelsResolver

Интерфейс для разрешения OpenAPI `$ref` в Dart типы моделей.

```dart
abstract class ModelsResolver {
  Future<String?> resolveRefToType(String ref);
  Future<String?> getImportPath(String typeName);
  Future<bool> isModelType(String typeName);
}
```

### FileBasedModelsResolver

Файловая реализация `ModelsResolver`.

```dart
class FileBasedModelsResolver implements ModelsResolver {
  FileBasedModelsResolver({
    required String projectDir,
    ModelsConfig? modelsConfig,
  });

  @override
  Future<String?> resolveRefToType(String ref);

  @override
  Future<String?> getImportPath(String typeName);

  @override
  Future<bool> isModelType(String typeName);
}
```

### NoOpModelsResolver

No-op реализация, которая возвращает `Map<String, dynamic>`.

```dart
class NoOpModelsResolver implements ModelsResolver {
  const NoOpModelsResolver();

  @override
  Future<String?> resolveRefToType(String ref) => Future.value(null);

  @override
  Future<String?> getImportPath(String typeName) => Future.value(null);

  @override
  Future<bool> isModelType(String typeName) => Future.value(false);
}
```

## API сгенерированного клиента

### ApiClient

Главный класс клиента, сгенерированный из OpenAPI спецификации.

```dart
class ApiClient {
  final ApiClientConfig _config;

  ApiClient(this._config);

  DefaultApi get defaultApi => DefaultApi(_config);

  Future<void> close();
  ApiClient withHeaders(Map<String, String> headers);
}
```

**Методы:**
- `close()`: Закрывает клиент и освобождает ресурсы
- `withHeaders(headers)`: Создает новый клиент с объединенными заголовками

### DefaultApi

Сгенерированный API класс, содержащий методы эндпоинтов.

```dart
class DefaultApi {
  final ApiClientConfig _config;

  DefaultApi(this._config);

  // Сгенерированные методы на основе OpenAPI спецификации
  Future<ReturnType> methodName({...parameters}) async {
    // Сгенерированная реализация
  }
}
```

Методы генерируются на основе значений `operationId` из OpenAPI спецификации.

## Определения типов

### RequestTransformer

```dart
typedef RequestTransformer = Future<HttpRequest> Function(HttpRequest request);
```

### ResponseTransformer

```dart
typedef ResponseTransformer = Future<HttpResponse> Function(HttpResponse response);
```
