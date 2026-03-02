import 'package:fieldops/core/auth/domain/entities/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldops/core/providers.dart';

class AuthViewModel extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() =>
      ref.watch(authRepositoryProvider).currentUser();

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          ),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}

final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, AppUser?>(AuthViewModel.new);
