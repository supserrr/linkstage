import 'package:flutter_bloc/flutter_bloc.dart';

/// Local UI state for profile photo picker uploads (no global DI).
class ProfilePhotoUploadCubit extends Cubit<bool> {
  ProfilePhotoUploadCubit() : super(false);

  void setUploading(bool value) => emit(value);
}
