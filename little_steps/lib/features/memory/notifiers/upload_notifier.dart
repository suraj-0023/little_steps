import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/memory_providers.dart';
import '../models/memory.dart';

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

  Future<Memory?> uploadPhoto(File photo, {String? caption, String? memoryId}) async {
    final user = _ref.read(currentUserProvider);
    if (user?.familyId == null) return null;

    state = const UploadInProgress();
    try {
      final memory = await _ref.read(memoryRepositoryProvider).uploadMemory(
            familyId: user!.familyId!,
            uploadedBy: user.uid,
            photo: photo,
            caption: caption,
            memoryId: memoryId,
          );
      state = const UploadSuccess();
      return memory;
    } catch (e) {
      state = UploadError(e.toString());
      return null;
    }
  }

  void reset() => state = const UploadIdle();
}

final uploadNotifierProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref);
});
