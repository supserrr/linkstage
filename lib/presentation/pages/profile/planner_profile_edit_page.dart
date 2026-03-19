import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../widgets/atoms/glass_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_borders.dart';
import '../../../core/utils/event_location_utils.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/planner_profile_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/collaboration_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/planner_profile_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../core/router/auth_redirect.dart';
import '../../bloc/planner_profile/planner_profile_cubit.dart';
import '../../bloc/planner_profile/planner_profile_state.dart';
import '../../widgets/molecules/chip_editor.dart';
import '../../widgets/molecules/empty_state_dotted.dart';
import '../../widgets/molecules/profile_edit_section.dart';
import '../../widgets/molecules/profile_edit_section_card.dart';
import '../../widgets/molecules/profile_photo_card.dart';
import '../../widgets/molecules/profile_save_bar.dart';

/// Event planner profile edit page.
class PlannerProfileEditPage extends StatelessWidget {
  const PlannerProfileEditPage({super.key});

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
      create: (_) => PlannerProfileCubit(
        sl<UserRepository>(),
        sl<EventRepository>(),
        sl<BookingRepository>(),
        sl<CollaborationRepository>(),
        sl<ProfileRepository>(),
        sl<PlannerProfileRepository>(),
        user.id,
        viewingUserId: user.id,
      ),
      child: const _PlannerProfileView(),
    );
  }
}

class _PlannerProfileView extends StatelessWidget {
  const _PlannerProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: BlocConsumer<PlannerProfileCubit, PlannerProfileState>(
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
            context.pop();
          }
        },
        builder: (context, state) {
          if (state.error != null && state.user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<PlannerProfileCubit>().refresh(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.isLoading && state.user == null) {
            return Center(
              child: LoadingAnimationWidget.stretchedDots(
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
            );
          }
          final user = state.user;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          final profile =
              state.plannerProfile ?? PlannerProfileEntity(userId: user.id);
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  ProfilePhotoCard(
                    onPhotoUpdated: () =>
                        context.read<PlannerProfileCubit>().refresh(),
                  ),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.person_outline,
                    title: 'Your name',
                    subtitle: 'How you appear across the app and to others',
                    child: ProfileEditSection(
                      title: 'Display name',
                      child: TextFormField(
                        initialValue:
                            profile.displayName ?? user.displayName ?? '',
                        decoration: const InputDecoration(
                          hintText: 'e.g. Jane Smith',
                        ),
                        maxLength: 80,
                        onChanged: (v) => context
                            .read<PlannerProfileCubit>()
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
                              'e.g. Corporate and wedding event planner with 10+ years experience...',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (v) =>
                            context.read<PlannerProfileCubit>().setBio(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.badge_outlined,
                    title: 'Role',
                    subtitle:
                        'Shown in Hosted by section on your events (e.g. Event Planner)',
                    child: ProfileEditSection(
                      title: 'Role or title',
                      child: TextFormField(
                        initialValue: profile.role ?? '',
                        decoration: const InputDecoration(
                          hintText: 'e.g. Event Planner, Wedding Planner',
                        ),
                        onChanged: (v) =>
                            context.read<PlannerProfileCubit>().setRole(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.work_outline,
                    title: 'What you do',
                    subtitle: 'Event types help creatives and clients find you',
                    child: ProfileEditSection(
                      title: 'Event types or specializations',
                      subtitle: 'e.g. Weddings, Corporate, Concerts',
                      child: ChipEditor(
                        values: profile.eventTypes,
                        hintText: 'Add type',
                        onChanged: (v) => context
                            .read<PlannerProfileCubit>()
                            .setEventTypes(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    subtitle: 'Where you\'re based',
                    child: ProfileEditSection(
                      title: 'Location',
                      subtitle: 'City or region where you\'re based',
                      child: TextFormField(
                        initialValue: profile.location,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Los Angeles, CA',
                        ),
                        onChanged: (v) =>
                            context.read<PlannerProfileCubit>().setLocation(v),
                      ),
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
                        hintText: 'e.g. English, Spanish',
                        onChanged: (v) =>
                            context.read<PlannerProfileCubit>().setLanguages(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileEditSectionCard(
                    icon: Icons.event_note,
                    title: 'Past events',
                    subtitle:
                        'Choose which past events to show on your profile',
                    child: state.pastEvents.isEmpty
                        ? EmptyStateDotted(
                            icon: Icons.event_outlined,
                            headline: 'No past events yet',
                            description:
                                'Add past events in your event management.',
                            compact: true,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: state.pastEvents
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _PastEventRow(
                                      event: e,
                                      onShowOnProfileChanged: (show) => context
                                          .read<PlannerProfileCubit>()
                                          .setEventShowOnProfile(e, show),
                                    ),
                                  ),
                                )
                                .toList(),
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
                  onSave: () => context.read<PlannerProfileCubit>().save(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PastEventRow extends StatelessWidget {
  const _PastEventRow({
    required this.event,
    required this.onShowOnProfileChanged,
  });

  final EventEntity event;
  final void Function(bool) onShowOnProfileChanged;

  @override
  Widget build(BuildContext context) {
    final dateStr = event.date != null
        ? '${event.date!.day}/${event.date!.month}/${event.date!.year}'
        : '—';
    final locationLine = getEventLocationDisplayLine(
      event,
      isPlanner: true,
      hasAcceptedBooking: false,
    );
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (event.imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CachedNetworkImage(
                        imageUrl: event.imageUrls.first,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.event,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '$locationLine · $dateStr',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Show on profile',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Switch(
                value: event.showOnProfile,
                onChanged: (v) => onShowOnProfileChanged(v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
