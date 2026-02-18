/// Example demonstrating integration with Riverpod state management.
///
/// This example shows how to use the generated API client with Riverpod
/// for state management in Flutter applications.
///
/// Prerequisites:
/// - Add `flutter_riverpod` to your `pubspec.yaml`:
///   ```yaml
///   dependencies:
///     flutter_riverpod: ^2.0.0
///   ```

import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';
// import 'package:your_app/api_client/api_client.dart'; // Generated client
// import 'package:your_app/models/user.dart'; // Generated models

// Example 1: Simple Provider for API Client
// ==========================================

/// Provider that creates and configures the API client.
///
/// This provider creates a singleton instance of the API client
/// that can be used throughout the app.
/*
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    auth: AuthConfig(
      bearerTokenEnv: 'API_BEARER_TOKEN',
    ),
    requestInterceptors: [
      LoggingInterceptor.console(),
    ],
    responseInterceptors: [
      RetryInterceptor(maxRetries: 3),
    ],
  );
  
  return ApiClient(config);
});
*/

// Example 2: FutureProvider for fetching data
// =============================================

/// Provider that fetches a list of users.
///
/// Automatically handles loading, error, and data states.
/*
final usersProvider = FutureProvider<List<User>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final users = await client.defaultApi.getUsers();
  return users;
});
*/

// Example 3: StateNotifier for complex state management
// ======================================================

/// State class for user list management.
/*
class UserListState {
  final List<User> users;
  final bool isLoading;
  final String? error;

  UserListState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserListState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
*/

/// StateNotifier for managing user list state.
/*
class UserListNotifier extends StateNotifier<UserListState> {
  UserListNotifier(this._client) : super(UserListState());

  final ApiClient _client;

  /// Load users from the API.
  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final users = await _client.defaultApi.getUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Refresh the user list.
  Future<void> refresh() async {
    await loadUsers();
  }

  /// Add a new user.
  Future<void> addUser(User user) async {
    try {
      final createdUser = await _client.defaultApi.createUser(user);
      state = state.copyWith(
        users: [...state.users, createdUser],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a user.
  Future<void> deleteUser(String userId) async {
    try {
      await _client.defaultApi.deleteUser(userId: userId);
      state = state.copyWith(
        users: state.users.where((u) => u.id != userId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
*/

/// Provider for UserListNotifier.
/*
final userListNotifierProvider =
    StateNotifierProvider<UserListNotifier, UserListState>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserListNotifier(client);
});
*/

// Example 4: Auto-dispose provider with error handling
// =====================================================

/// Provider that fetches a single user by ID.
///
/// Automatically disposes when not in use.
/*
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final client = ref.watch(apiClientProvider);
  
  try {
    final user = await client.defaultApi.getUser(userId: userId);
    return user;
  } on ApiAuthException catch (e) {
    // Handle authentication errors
    throw Exception('Authentication failed: ${e.message}');
  } on ApiServerException catch (e) {
    // Handle server errors
    throw Exception('Server error: ${e.message}');
  } on TimeoutException catch (e) {
    // Handle timeout errors
    throw Exception('Request timed out: ${e.message}');
  }
});
*/

// Example 5: Provider with refresh capability
// ============================================

/// Provider that can be refreshed manually.
/*
final refreshableUsersProvider = FutureProvider<List<User>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return await client.defaultApi.getUsers();
});
*/

// Example 6: Using providers in Flutter widgets
// ==============================================

/// Example Flutter widget using Riverpod providers.
/*
class UsersListWidget extends ConsumerWidget {
  const UsersListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return usersAsync.when(
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            title: Text(user.name ?? 'Unknown'),
            subtitle: Text(user.email ?? ''),
          );
        },
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
*/

/// Example widget using StateNotifier.
/*
class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(userListNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : ListView.builder(
                  itemCount: state.users.length,
                  itemBuilder: (context, index) {
                    final user = state.users[index];
                    return ListTile(
                      title: Text(user.name ?? 'Unknown'),
                      subtitle: Text(user.email ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          ref
                              .read(userListNotifierProvider.notifier)
                              .deleteUser(user.id!);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add user screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
*/

// Example 7: Provider with authentication
// ======================================

/// Provider for authentication state.
/*
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.token,
    this.error,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._client) : super(AuthState());

  final ApiClient _client;

  Future<void> login(String email, String password) async {
    try {
      final response = await _client.defaultApi.login(
        body: {'email': email, 'password': password},
      );
      
      // Update client config with new token
      // (This would require recreating the client or updating config)
      
      state = AuthState(
        isAuthenticated: true,
        token: response['token'] as String?,
      );
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  void logout() {
    state = AuthState();
  }
}
*/

void main() {
  print('Riverpod integration examples');
  print('See comments in the file for complete examples');
}
