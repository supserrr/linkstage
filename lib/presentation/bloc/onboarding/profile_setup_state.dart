import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/entities/profile_entity.dart';

/// State for profile setup flow.
class ProfileSetupState extends Equatable {
  const ProfileSetupState({
    this.username,
    this.photoFile,
    this.photoUrl,
    this.isUploadingPhoto = false,
    this.photoUploadError,
    this.displayName = '',
    this.bio = '',
    this.location = '',
    this.category,
    this.priceRange = '',
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  const ProfileSetupState.initial()
      : username = null,
        photoFile = null,
        photoUrl = null,
        isUploadingPhoto = false,
        photoUploadError = null,
        displayName = '',
        bio = '',
        location = '',
        category = null,
        priceRange = '',
        isLoading = true,
        error = null,
        success = false;

  final String? username;
  final XFile? photoFile;
  final String? photoUrl;
  final bool isUploadingPhoto;
  final String? photoUploadError;
  final String displayName;
  final String bio;
  final String location;
  final ProfileCategory? category;
  final String priceRange;
  final bool isLoading;
  final String? error;
  final bool success;

  ProfileSetupState copyWith({
    String? username,
    XFile? photoFile,
    bool clearPhotoFile = false,
    String? photoUrl,
    bool clearPhotoUrl = false,
    bool? isUploadingPhoto,
    String? photoUploadError,
    bool clearPhotoUploadError = false,
    String? displayName,
    String? bio,
    String? location,
    ProfileCategory? category,
    String? priceRange,
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return ProfileSetupState(
      username: username ?? this.username,
      photoFile: clearPhotoFile ? null : (photoFile ?? this.photoFile),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      photoUploadError: clearPhotoUploadError ? null : (photoUploadError ?? this.photoUploadError),
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      category: category ?? this.category,
      priceRange: priceRange ?? this.priceRange,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }

  @override
  List<Object?> get props => [
        username,
        photoFile,
        photoUrl,
        isUploadingPhoto,
        photoUploadError,
        displayName,
        bio,
        location,
        category,
        priceRange,
        isLoading,
        error,
        success,
      ];
}
