/// Example demonstrating integration with BLoC state management.
///
/// This example shows how to use the generated API client with BLoC
/// for state management in Flutter applications.
///
/// Prerequisites:
/// - Add `flutter_bloc` to your `pubspec.yaml`:
///   ```yaml
///   dependencies:
///     flutter_bloc: ^8.0.0
///     equatable: ^2.0.0
///   ```

import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';
// import 'package:your_app/api_client/api_client.dart'; // Generated client
// import 'package:your_app/models/user.dart'; // Generated models
// import 'package:equatable/equatable.dart';

// Example 1: User List BLoC
// =========================

/// Events for UserListBloc.
/*
abstract class UserListEvent extends Equatable {
  const UserListEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends UserListEvent {
  const LoadUsersEvent();
}

class RefreshUsersEvent extends UserListEvent {
  const RefreshUsersEvent();
}

class AddUserEvent extends UserListEvent {
  final User user;

  const AddUserEvent(this.user);

  @override
  List<Object?> get props => [user];
}

class DeleteUserEvent extends UserListEvent {
  final String userId;

  const DeleteUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
*/

/// States for UserListBloc.
/*
abstract class UserListState extends Equatable {
  const UserListState();

  @override
  List<Object?> get props => [];
}

class UserListInitial extends UserListState {
  const UserListInitial();
}

class UserListLoading extends UserListState {
  const UserListLoading();
}

class UserListLoaded extends UserListState {
  final List<User> users;

  const UserListLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UserListError extends UserListState {
  final String message;

  const UserListError(this.message);

  @override
  List<Object?> get props => [message];
}
*/

/// BLoC for managing user list state.
/*
class UserListBloc extends Bloc<UserListEvent, UserListState> {
  UserListBloc(this._apiClient) : super(const UserListInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<RefreshUsersEvent>(_onRefreshUsers);
    on<AddUserEvent>(_onAddUser);
    on<DeleteUserEvent>(_onDeleteUser);
  }

  final ApiClient _apiClient;

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserListLoading());

    try {
      final users = await _apiClient.defaultApi.getUsers();
      emit(UserListLoaded(users));
    } on ApiAuthException catch (e) {
      emit(UserListError('Authentication failed: ${e.message}'));
    } on ApiServerException catch (e) {
      emit(UserListError('Server error: ${e.message}'));
    } on TimeoutException catch (e) {
      emit(UserListError('Request timed out: ${e.message}'));
    } catch (e) {
      emit(UserListError('Unexpected error: $e'));
    }
  }

  Future<void> _onRefreshUsers(
    RefreshUsersEvent event,
    Emitter<UserListState> emit,
  ) async {
    // Keep current state if loaded, otherwise show loading
    if (state is UserListLoaded) {
      // Optionally show a subtle loading indicator
    } else {
      emit(const UserListLoading());
    }

    try {
      final users = await _apiClient.defaultApi.getUsers();
      emit(UserListLoaded(users));
    } catch (e) {
      emit(UserListError('Failed to refresh: $e'));
    }
  }

  Future<void> _onAddUser(
    AddUserEvent event,
    Emitter<UserListState> emit,
  ) async {
    if (state is UserListLoaded) {
      final currentState = state as UserListLoaded;
      
      try {
        final createdUser = await _apiClient.defaultApi.createUser(event.user);
        emit(UserListLoaded([...currentState.users, createdUser]));
      } catch (e) {
        emit(UserListError('Failed to add user: $e'));
      }
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserListState> emit,
  ) async {
    if (state is UserListLoaded) {
      final currentState = state as UserListLoaded;
      
      try {
        await _apiClient.defaultApi.deleteUser(userId: event.userId);
        emit(UserListLoaded(
          currentState.users.where((u) => u.id != event.userId).toList(),
        ));
      } catch (e) {
        emit(UserListError('Failed to delete user: $e'));
      }
    }
  }
}
*/

// Example 2: User Detail BLoC
// ============================

/// Events for UserDetailBloc.
/*
abstract class UserDetailEvent extends Equatable {
  const UserDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserEvent extends UserDetailEvent {
  final String userId;

  const LoadUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUserEvent extends UserDetailEvent {
  final User user;

  const UpdateUserEvent(this.user);

  @override
  List<Object?> get props => [user];
}
*/

/// States for UserDetailBloc.
/*
abstract class UserDetailState extends Equatable {
  const UserDetailState();

  @override
  List<Object?> get props => [];
}

class UserDetailInitial extends UserDetailState {
  const UserDetailInitial();
}

class UserDetailLoading extends UserDetailState {
  const UserDetailLoading();
}

class UserDetailLoaded extends UserDetailState {
  final User user;

  const UserDetailLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserDetailError extends UserDetailState {
  final String message;

  const UserDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
*/

/// BLoC for managing user detail state.
/*
class UserDetailBloc extends Bloc<UserDetailEvent, UserDetailState> {
  UserDetailBloc(this._apiClient) : super(const UserDetailInitial()) {
    on<LoadUserEvent>(_onLoadUser);
    on<UpdateUserEvent>(_onUpdateUser);
  }

  final ApiClient _apiClient;

  Future<void> _onLoadUser(
    LoadUserEvent event,
    Emitter<UserDetailState> emit,
  ) async {
    emit(const UserDetailLoading());

    try {
      final user = await _apiClient.defaultApi.getUser(userId: event.userId);
      emit(UserDetailLoaded(user));
    } catch (e) {
      emit(UserDetailError('Failed to load user: $e'));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UserDetailState> emit,
  ) async {
    if (state is UserDetailLoaded) {
      try {
        final updatedUser = await _apiClient.defaultApi.updateUser(
          userId: event.user.id!,
          body: event.user,
        );
        emit(UserDetailLoaded(updatedUser));
      } catch (e) {
        emit(UserDetailError('Failed to update user: $e'));
      }
    }
  }
}
*/

// Example 3: Authentication BLoC
// ===============================

/// Events for AuthBloc.
/*
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckAuthEvent extends AuthEvent {
  const CheckAuthEvent();
}
*/

/// States for AuthBloc.
/*
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String token;
  final User user;

  const AuthAuthenticated(this.token, this.user);

  @override
  List<Object?> get props => [token, user];
}

class AuthUnauthenticated extends AuthState {
  final String? error;

  const AuthUnauthenticated({this.error});

  @override
  List<Object?> get props => [error];
}
*/

/// BLoC for managing authentication state.
/*
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._apiClient) : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
  }

  final ApiClient _apiClient;

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await _apiClient.defaultApi.login(
        body: {
          'email': event.email,
          'password': event.password,
        },
      );

      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      // Update API client config with new token
      // (This would require recreating the client or updating config)

      emit(AuthAuthenticated(token, user));
    } on ApiAuthException catch (e) {
      emit(AuthUnauthenticated(error: 'Invalid credentials: ${e.message}'));
    } catch (e) {
      emit(AuthUnauthenticated(error: 'Login failed: $e'));
    }
  }

  void _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthUnauthenticated());
  }

  Future<void> _onCheckAuth(
    CheckAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Check if user is authenticated (e.g., from secure storage)
    // This is a simplified example
    emit(const AuthUnauthenticated());
  }
}
*/

// Example 4: Using BLoC in Flutter widgets
// ========================================

/// Example Flutter widget using BLoC.
/*
class UsersListWidget extends StatelessWidget {
  const UsersListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserListBloc(
        // Get ApiClient from dependency injection or context
        // ApiClient(config),
      )..add(const LoadUsersEvent()),
      child: BlocBuilder<UserListBloc, UserListState>(
        builder: (context, state) {
          if (state is UserListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserListError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is UserListLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<UserListBloc>().add(const RefreshUsersEvent());
              },
              child: ListView.builder(
                itemCount: state.users.length,
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  return ListTile(
                    title: Text(user.name ?? 'Unknown'),
                    subtitle: Text(user.email ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        context.read<UserListBloc>().add(
                              DeleteUserEvent(user.id!),
                            );
                      },
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
*/

/// Example widget with BLoC listener for side effects.
/*
class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserListBloc(
        // Get ApiClient from dependency injection
      )..add(const LoadUsersEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Users'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<UserListBloc>().add(const RefreshUsersEvent());
              },
            ),
          ],
        ),
        body: BlocListener<UserListBloc, UserListState>(
          listener: (context, state) {
            if (state is UserListError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: BlocBuilder<UserListBloc, UserListState>(
            builder: (context, state) {
              if (state is UserListLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is UserListError) {
                return Center(child: Text('Error: ${state.message}'));
              } else if (state is UserListLoaded) {
                return ListView.builder(
                  itemCount: state.users.length,
                  itemBuilder: (context, index) {
                    final user = state.users[index];
                    return ListTile(
                      title: Text(user.name ?? 'Unknown'),
                      subtitle: Text(user.email ?? ''),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to add user screen
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
*/

// Example 5: BLoC with dependency injection
// =========================================

/// Repository pattern for API calls.
/*
class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<List<User>> getUsers() async {
    return await _apiClient.defaultApi.getUsers();
  }

  Future<User> getUser(String userId) async {
    return await _apiClient.defaultApi.getUser(userId: userId);
  }

  Future<User> createUser(User user) async {
    return await _apiClient.defaultApi.createUser(user);
  }

  Future<User> updateUser(String userId, User user) async {
    return await _apiClient.defaultApi.updateUser(
      userId: userId,
      body: user,
    );
  }

  Future<void> deleteUser(String userId) async {
    return await _apiClient.defaultApi.deleteUser(userId: userId);
  }
}
*/

/// BLoC using repository pattern.
/*
class UserListBlocWithRepository extends Bloc<UserListEvent, UserListState> {
  UserListBlocWithRepository(this._repository)
      : super(const UserListInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
  }

  final UserRepository _repository;

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserListState> emit,
  ) async {
    emit(const UserListLoading());

    try {
      final users = await _repository.getUsers();
      emit(UserListLoaded(users));
    } catch (e) {
      emit(UserListError('Failed to load users: $e'));
    }
  }
}
*/

void main() {
  print('BLoC integration examples');
  print('See comments in the file for complete examples');
}
