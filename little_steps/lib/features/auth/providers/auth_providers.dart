import 'package:flutter_riverpod/flutter_riverpod.dart';

// Placeholder until Firebase is configured.
// Returns null (not logged in) so the router sends users to /auth.
final authStateProvider = StreamProvider<String?>((ref) {
  return const Stream.empty();
});
