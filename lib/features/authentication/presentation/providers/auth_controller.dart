import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/providers/providers.dart';
import '../../data/auth_remote_datasource.dart';
import '../../data/auth_repository_impl.dart';
import '../../data/local_auth_repository.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

// ---------- Providers de dependencias ----------
/// Aquí decides de dónde sale la sesión: local (sin API) o remota.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Env.useMockAuth) {
    return LocalAuthRepository(ref.watch(secureStorageProvider));
  }
  return AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(dioProvider)),
    ref.watch(tokenStorageProvider),
  );
});

// ---------- Estado ----------
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------- Controller ----------
class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    Future.microtask(restoreSession);
    return const AuthState();
  }

  Future<void> restoreSession() async {
    final user = await _repo.restoreSession();
    state = user == null
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, error: f.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Error inesperado.');
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
