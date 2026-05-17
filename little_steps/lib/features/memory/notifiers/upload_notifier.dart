import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/memory_providers.dart';

sealed class UploadState {
  const UploadState();
}

class UploadIdle extends UploadState {
  const UploadIdle();
}

class UploadInProgress extends UploadState {
  const UploadInProgress();
}

class UploadSuccess extends UploadState {
  const UploadSuccess();
}

class UploadError extends UploadState {
  const UploadError(this.message);
  final String message;
}

class UploadNotifier extends StateNotifier<UploadState> {
  UploadNotifier(this._ref) : super(const UploadIdle());

  final Ref _ref;

  Future<void> uploadPhoto(File photo, {String? caption}) async {
    final user = _ref.read(currentUserProvider);
    if (user?.familyId == null) return;

    state = const UploadInProgress();
    try {
      await _ref.read(memoryRepositoryProvider).uploadMemory(
            familyId: user!.familyId!,
            uploadedBy: user.uid,
            photo: photo,
            caption: caption,
          );
      state = const UploadSuccess();
    } catch (e) {
      state = UploadError(e.toString());
    }
  }

  void reset() => state = const UploadIdle();
}

final uploadNotifierProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref);
});
