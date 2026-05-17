import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
