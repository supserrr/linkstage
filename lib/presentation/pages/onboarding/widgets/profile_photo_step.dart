import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/toast_utils.dart';
import '../../../bloc/onboarding/profile_setup_cubit.dart';
import '../../../bloc/onboarding/profile_setup_state.dart';
import '../../../widgets/atoms/app_button.dart';
import '../../../widgets/atoms/glass_card.dart';

class ProfilePhotoStep extends StatefulWidget {
  const ProfilePhotoStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<ProfilePhotoStep> createState() => _ProfilePhotoStepState();
}

class _ProfilePhotoStepState extends State<ProfilePhotoStep> {
  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (x != null && context.mounted) {
      context.read<ProfileSetupCubit>().setPhoto(x);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/images/profile_page_illustration_dark.svg'
        : 'assets/images/profile_page_illustration_light.svg';

    return BlocConsumer<ProfileSetupCubit, ProfileSetupState>(
      listenWhen: (a, b) => a.photoUploadError != b.photoUploadError,
      listener: (context, state) {
        if (state.photoUploadError != null) {
          showToast(context, state.photoUploadError!, isError: true);
        }
      },
      builder: (context, state) {
        final photoFile = state.photoFile;
        final photoUrl = state.photoUrl;
        final isUploadingPhoto = state.isUploadingPhoto;
        final hasPhoto = photoFile != null || photoUrl != null;

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SvgPicture.asset(asset, fit: BoxFit.contain),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Text(
                          'Add a profile photo',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isUploadingPhoto
                                ? null
                                : () => _pickImage(context),
                            borderRadius: BorderRadius.circular(60),
                            child: FutureBuilder<Uint8List>(
                              future: photoFile?.readAsBytes(),
                              builder: (context, snapshot) {
                                final bytes = snapshot.data;
                                final hasLocalImage =
                                    bytes != null && bytes.isNotEmpty;
                                final hasRemoteImage =
                                    photoUrl != null && photoUrl.isNotEmpty;
                                return Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      width: 2,
                                      color: hasPhoto
                                          ? Colors.transparent
                                          : theme.colorScheme.primary,
                                    ),
                                    color: hasPhoto
                                        ? null
                                        : theme.colorScheme.primaryContainer,
                                    image: hasLocalImage
                                        ? DecorationImage(
                                            image: MemoryImage(bytes),
                                            fit: BoxFit.cover,
                                          )
                                        : hasRemoteImage
                                        ? DecorationImage(
                                            image: CachedNetworkImageProvider(
                                              photoUrl,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: hasPhoto
                                      ? (photoUrl != null
                                            ? Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: theme
                                                        .colorScheme
                                                        .onPrimary,
                                                  ),
                                                ),
                                              )
                                            : null)
                                      : Center(
                                          child: Icon(
                                            Icons.add_a_photo,
                                            size: 36,
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Next',
                        isLoading: isUploadingPhoto,
                        onPressed: hasPhoto
                            ? () async {
                                final ok = await context
                                    .read<ProfileSetupCubit>()
                                    .uploadSelectedPhoto();
                                if (ok && context.mounted) widget.onNext();
                              }
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: isUploadingPhoto
                            ? null
                            : () {
                                context
                                    .read<ProfileSetupCubit>()
                                    .clearPhotoAndError();
                                widget.onNext();
                              },
                        child: const Text('Skip for now'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
