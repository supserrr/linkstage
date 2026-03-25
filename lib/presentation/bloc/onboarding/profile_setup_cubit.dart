import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/datasources/portfolio_storage_datasource.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/usecases/user/upsert_user_usecase.dart';
import 'profile_setup_state.dart';

/// Manages profile setup flow state and persistence.
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit(
    this._user,
    this._upsertUser,
    this._profileRepository,
    this._userRepository,
    this._storage,
    this._authRepository, {
    ProfileSetupState? initialDraft,
  }) : super(ProfileSetupState.initial()) {
    _loadInitial(initialDraft);
  }

  final UserEntity _user;
  final UpsertUserUseCase _upsertUser;
  final ProfileRepository _profileRepository;
  final UserRepository _userRepository;
  final PortfolioStorageDataSource _storage;
  final AuthRepository _authRepository;

  void _loadInitial([ProfileSetupState? draft]) {
    if (draft != null) {
      emit(draft);
      return;
    }
    emit(
      state.copyWith(displayName: _user.displayName ?? '', isLoading: false),
    );
  }

  void setUsername(String value) => emit(state.copyWith(username: value));

  void setPhoto(XFile? file) => emit(
    state.copyWith(
      photoFile: file,
      clearPhotoFile: file == null,
      clearPhotoUrl: file == null,
      clearPhotoUploadError: file == null,
    ),
  );

  /// Uploads the selected photo. Returns true on success. Caller should navigate
  /// to next step on success.
  Future<bool> uploadSelectedPhoto() async {
    if (state.photoFile == null || state.photoUrl != null) {
      return state.photoUrl != null;
    }
    final userId = _authRepository.currentUser?.id ?? _user.id;
    if (userId.isEmpty) {
      emit(
        state.copyWith(
          photoUploadError: 'Please sign in again to upload a photo.',
          isUploadingPhoto: false,
        ),
      );
      return false;
    }
    emit(state.copyWith(isUploadingPhoto: true, clearPhotoUploadError: true));
    try {
      final url = await _storage.uploadProfilePhoto(state.photoFile!, userId);
      emit(
        state.copyWith(
          photoUrl: url,
          isUploadingPhoto: false,
          clearPhotoUploadError: true,
        ),
      );
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode && Platform.environment['FLUTTER_TEST'] != 'true') {
        debugPrint('Profile photo upload failed: $e');
        debugPrint(stackTrace.toString());
      }
      final message = e.toString().replaceAll('Exception:', '').trim();
      emit(
        state.copyWith(
          photoUploadError: message.isNotEmpty
              ? message
              : 'Upload failed. Please try again.',
          isUploadingPhoto: false,
        ),
      );
      return false;
    }
  }

  void clearPhotoAndError() => emit(
    state.copyWith(
      clearPhotoFile: true,
      clearPhotoUrl: true,
      clearPhotoUploadError: true,
    ),
  );

  void setDisplayName(String value) => emit(state.copyWith(displayName: value));

  void setBio(String value) => emit(state.copyWith(bio: value));

  void setLocation(String value) => emit(state.copyWith(location: value));

  void setCategory(ProfileCategory? value) =>
      emit(state.copyWith(category: value));

  void setPriceRange(String value) => emit(state.copyWith(priceRange: value));

  Future<bool> checkUsernameAvailable(String username) async {
    if (username.length < 3) return false;
    return _userRepository.checkUsernameAvailable(username);
  }

  Future<void> submit() async {
    if (state.username == null || state.username!.isEmpty) {
      emit(state.copyWith(error: 'Username is required'));
      return;
    }
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final photoUrl = state.photoUrl ?? _user.photoUrl;
      final username = state.username!.toLowerCase().trim();
      final userWithUsername = UserEntity(
        id: _user.id,
        email: _user.email,
        emailVerified: _user.emailVerified,
        username: username,
        displayName: state.displayName.isNotEmpty
            ? state.displayName
            : username,
        photoUrl: photoUrl,
        role: _user.role,
      );
      await _upsertUser(userWithUsername);

      final profile = ProfileEntity(
        id: username,
        userId: _user.id,
        username: username,
        bio: state.bio,
        category: state.category,
        priceRange: state.priceRange,
        location: state.location,
        displayName: state.displayName.isNotEmpty
            ? state.displayName
            : username,
      );
      await _profileRepository.upsertProfile(profile);

      emit(state.copyWith(isLoading: false, success: true));
    } catch (e) {
      final message = e.toString().replaceAll('Exception:', '').trim();
      emit(
        state.copyWith(
          isLoading: false,
          error: message.isNotEmpty
              ? message
              : 'Something went wrong. Please try again.',
        ),
      );
    }
  }
}
