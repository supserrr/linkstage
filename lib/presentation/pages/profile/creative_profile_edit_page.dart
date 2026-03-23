import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/creative_profile/creative_profile_cubit.dart';
import '../../bloc/creative_profile/creative_profile_state.dart';
import '../../bloc/profile_photo_upload/profile_photo_upload_cubit.dart';
import '../../../core/constants/app_borders.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/datasources/portfolio_storage_datasource.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/auth_redirect.dart';
import '../../widgets/atoms/glass_card.dart';
import '../../widgets/molecules/chip_editor.dart';
import '../../widgets/molecules/profile_edit_section.dart';
import '../../widgets/molecules/profile_edit_section_card.dart';
import '../../widgets/molecules/profile_photo_card.dart';
import '../../widgets/molecules/profile_save_bar.dart';

/// Creative professional profile edit page.
class CreativeProfileEditPage extends StatelessWidget {
  const CreativeProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthRedirectNotifier>().user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.stretchedDots(
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
        ),
      );
    }
    return BlocProvider(
      create: (_) => CreativeProfileCubit(
        sl<ProfileRepository>(),
        sl<ReviewRepository>(),
        sl<BookingRepository>(),
        sl<UserRepository>(),
        user.id,
      ),
      child: const _CreativeProfileView(),
    );
  }
}

class _CreativeProfileView extends StatelessWidget {
  const _CreativeProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: BlocConsumer<CreativeProfileCubit, CreativeProfileState>(
        listenWhen: (prev, curr) {
          if (prev.isSaving && !curr.isSaving && curr.error == null) {
            return true;
          }
          if (curr.error != prev.error && curr.error != null) return true;
          return false;
        },
        listener: (context, state) {
          if (state.error != null) {
            showToast(context, state.error!, isError: true);
          } else {
            sl<AuthRedirectNotifier>().refresh();
            context.go(AppRoutes.viewProfile);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.profile == null) {
            return Center(
              child: LoadingAnimationWidget.stretchedDots(
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
            );
          }
          final profile = state.profile;
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }
          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  const ProfilePhotoCard(compact: false, inline: true),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.person_outline,
                    title: 'Your name',
                    subtitle: 'How you appear across the app and to others',
                    child: ProfileEditSection(
                      title: 'Display name',
                      child: TextFormField(
                        initialValue:
                            profile.displayName ??
                            sl<AuthRedirectNotifier>().user?.displayName ??
                            '',
                        decoration: const InputDecoration(
                          hintText: 'e.g. Marie Mukamana',
                        ),
                        maxLength: 80,
                        onChanged: (v) => context
                            .read<CreativeProfileCubit>()
                            .setDisplayName(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.description_outlined,
                    title: 'About you',
                    subtitle: 'Describe your experience and what you offer',
                    child: ProfileEditSection(
                      title: 'Bio',
                      child: TextFormField(
                        initialValue: profile.bio,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. DJ and MC for weddings and events across Rwanda...',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (v) =>
                            context.read<CreativeProfileCubit>().setBio(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.work_outline,
                    title: 'What you do',
                    subtitle: 'Roles and event types help clients find you',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileEditSection(
                          title: 'Your role(s)',
                          subtitle: 'e.g. DJ, Photographer, Videographer',
                          child: ChipEditor(
                            values: profile.professions,
                            hintText: 'Add role',
                            onChanged: (v) => context
                                .read<CreativeProfileCubit>()
                                .setProfessions(v),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ProfileEditSection(
                          title: 'Event types or specializations',
                          subtitle: 'e.g. Weddings, Corporate, Concerts',
                          child: ChipEditor(
                            values: profile.services,
                            hintText: 'Add type',
                            onChanged: (v) => context
                                .read<CreativeProfileCubit>()
                                .setServices(v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Location & rates',
                    subtitle: 'Where you work and how you charge',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileEditSection(
                          title: 'Location',
                          subtitle: 'City or region where you\'re based',
                          child: TextFormField(
                            initialValue: profile.location,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Kigali, or Musanze, Northern Province',
                            ),
                            onChanged: (v) => context
                                .read<CreativeProfileCubit>()
                                .setLocation(v),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ProfileEditSection(
                          title: 'Starting rate or price range',
                          subtitle: 'Include currency and unit (e.g. per hour)',
                          child: TextFormField(
                            initialValue: profile.priceRange,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 75,000 RWF/hr or 50,000–150,000 RWF',
                            ),
                            onChanged: (v) => context
                                .read<CreativeProfileCubit>()
                                .setPriceRange(v),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ProfileEditSection(
                          title: 'Availability',
                          subtitle: 'Whether you\'re currently taking bookings',
                          child: _AvailabilitySelector(
                            value: profile.availability,
                            onChanged: (v) => context
                                .read<CreativeProfileCubit>()
                                .setAvailability(v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.language,
                    title: 'Languages',
                    subtitle: 'Optional – languages you can work in',
                    child: ProfileEditSection(
                      title: 'Add languages',
                      child: ChipEditor(
                        values: profile.languages,
                        hintText: 'e.g. Kinyarwanda, English, French',
                        onChanged: (v) => context
                            .read<CreativeProfileCubit>()
                            .setLanguages(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Portfolio',
                    subtitle: 'Photos or videos of your work',
                    child: BlocProvider(
                      create: (_) => ProfilePhotoUploadCubit(),
                      child: _PortfolioSection(
                        profile: profile,
                        userId: sl<AuthRedirectNotifier>().user!.id,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ProfileSaveBar(
                  isSaving: state.isSaving,
                  onSave: () => context.read<CreativeProfileCubit>().save(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AvailabilitySelector extends StatelessWidget {
  const _AvailabilitySelector({required this.value, required this.onChanged});

  final ProfileAvailability? value;
  final void Function(ProfileAvailability?) onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ProfileAvailability?>(
      segments: const [
        ButtonSegment<ProfileAvailability?>(
          value: ProfileAvailability.openToWork,
          label: Text('Open to work'),
          icon: Icon(Icons.check_circle_outline),
        ),
        ButtonSegment<ProfileAvailability?>(
          value: ProfileAvailability.notAvailable,
          label: Text('Not available'),
          icon: Icon(Icons.cancel_outlined),
        ),
      ],
      selected: {value ?? ProfileAvailability.openToWork},
      onSelectionChanged: (Set<ProfileAvailability?> s) {
        onChanged(s.isNotEmpty ? s.first : null);
      },
    );
  }
}

class _PortfolioSection extends StatelessWidget {
  const _PortfolioSection({required this.profile, required this.userId});

  final ProfileEntity profile;
  final String userId;

  Future<void> _showAddOptions(BuildContext context) async {
    final uploadCubit = context.read<ProfilePhotoUploadCubit>();
    final isVideo = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => GlassBottomSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Add photo'),
                onTap: () => Navigator.pop(ctx, false),
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Add video'),
                onTap: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (isVideo == null || !context.mounted) return;
    final picker = ImagePicker();
    final XFile? file = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
    if (file == null || !context.mounted) return;
    uploadCubit.setUploading(true);
    try {
      final storage = sl<PortfolioStorageDataSource>();
      final url = await storage.uploadPortfolioMedia(
        file,
        userId,
        isVideo: isVideo,
      );
      if (!context.mounted) return;
      final cubit = context.read<CreativeProfileCubit>();
      final p = cubit.state.profile;
      if (p == null) return;
      if (isVideo) {
        cubit.setPortfolioVideoUrls([...p.portfolioVideoUrls, url]);
      } else {
        cubit.setPortfolioUrls([...p.portfolioUrls, url]);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Upload failed: ${e.toString()}', isError: true);
      }
    } finally {
      if (context.mounted) {
        uploadCubit.setUploading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = profile.portfolioUrls;
    final videos = profile.portfolioVideoUrls;
    const itemSize = 80.0;
    const spacing = 8.0;

    return ProfileEditSection(
      title: 'Portfolio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<ProfilePhotoUploadCubit, bool>(
                  builder: (context, isUploading) {
                    return GestureDetector(
                      onTap: isUploading
                          ? null
                          : () => _showAddOptions(context),
                      child: Container(
                        width: itemSize,
                        height: itemSize,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.6),
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppBorders.chipRadius,
                          ),
                        ),
                        child: isUploading
                            ? Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: LoadingAnimationWidget.stretchedDots(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.add,
                                  size: 32,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: spacing),
                ...images.map(
                  (url) => Padding(
                    padding: const EdgeInsets.only(right: spacing),
                    child: _PortfolioThumb(
                      url: url,
                      isVideo: false,
                      itemSize: itemSize,
                      onRemove: () {
                        context.read<CreativeProfileCubit>().setPortfolioUrls(
                          images.where((u) => u != url).toList(),
                        );
                      },
                    ),
                  ),
                ),
                ...videos.map(
                  (url) => Padding(
                    padding: const EdgeInsets.only(right: spacing),
                    child: _PortfolioThumb(
                      url: url,
                      isVideo: true,
                      itemSize: itemSize,
                      onRemove: () {
                        context
                            .read<CreativeProfileCubit>()
                            .setPortfolioVideoUrls(
                              videos.where((u) => u != url).toList(),
                            );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioThumb extends StatelessWidget {
  const _PortfolioThumb({
    required this.url,
    required this.isVideo,
    required this.itemSize,
    required this.onRemove,
  });

  final String url;
  final bool isVideo;
  final double itemSize;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: itemSize,
          height: itemSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorders.chipRadius),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          child: isVideo
              ? Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 36,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Material(
            color: Theme.of(context).colorScheme.errorContainer,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
