import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';

class AuthState {
  final AppUser? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  bool get isAuthenticated => user != null;
  bool get isProvider => user?.role == 'PROVIDER';

  AuthState copyWith({AppUser? user, bool? loading, String? error}) => AuthState(
        user: user ?? this.user,
        loading: loading ?? this.loading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    final token = await TokenStorage.readToken();
    if (token == null) return;
    state = state.copyWith(loading: true);
    try {
      final res = await ApiClient.instance.client.get('/users/me');
      state = state.copyWith(user: AppUser.fromJson(res.data), loading: false);
    } catch (_) {
      await TokenStorage.clearToken(); // stale/invalid token — force re-login
      state = const AuthState();
    }
  }

  /// [role] must be 'CUSTOMER' or 'PROVIDER' — the register screen decides which,
  /// since this single app now serves both sides of the marketplace.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ApiClient.instance.client.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null) 'phone': phone,
      });
      await TokenStorage.saveToken(res.data['token'] as String);
      state = state.copyWith(user: AppUser.fromJson(res.data['user']), loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ApiClient.instance.client
          .post('/auth/login', data: {'email': email, 'password': password});
      await TokenStorage.saveToken(res.data['token'] as String);
      state = state.copyWith(user: AppUser.fromJson(res.data['user']), loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearToken();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
