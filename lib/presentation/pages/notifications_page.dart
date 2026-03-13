import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../widgets/atoms/glass_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../core/constants/app_icons.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/router/auth_redirect.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/notifications/notifications_cubit.dart';
import '../bloc/notifications/notifications_state.dart';
import '../widgets/atoms/section_header.dart';
import '../widgets/molecules/connection_error_overlay.dart';
import '../widgets/molecules/skeleton_loaders.dart';
import '../widgets/molecules/empty_state_illustrated.dart';

/// Page showing all recent notifications (bookings, collaborations).
/// Updates in real time via Firestore streams.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static String _formatTime(BuildContext context, DateTime at) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${at.day}/${at.month}/${at.year}';
  }

  static String _sectionFor(BuildContext context, DateTime at) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    if (day == today) return l10n.today;
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == yesterday) return l10n.yesterday;
    if (now.difference(day).inDays < 7) return l10n.thisWeek;
    return l10n.older;
  }

  static IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.bookingNewApplication:
      case NotificationType.bookingInvited:
      case NotificationType.bookingInvitationAccepted:
      case NotificationType.bookingInvitationDeclined:
        return AppIcons.applicants;
      case NotificationType.bookingAccepted:
      case NotificationType.bookingDeclined:
      case NotificationType.plannerNewEvent:
        return AppIcons.event;
      case NotificationType.collaborationNewProposal:
      case NotificationType.collaborationAccepted:
      case NotificationType.collaborationDeclined:
        return AppIcons.proposal;
      case NotificationType.chatNewMessage:
        return AppIcons.messages;
    }
  }

  static Color? _tintForType(NotificationType type, ColorScheme scheme) {
    switch (type) {
      case NotificationType.bookingAccepted:
      case NotificationType.bookingInvitationAccepted:
      case NotificationType.collaborationAccepted:
      case NotificationType.plannerNewEvent:
        return scheme.primary.withValues(alpha: 0.15);
      case NotificationType.bookingDeclined:
      case NotificationType.bookingInvitationDeclined:
      case NotificationType.collaborationDeclined:
        return scheme.error.withValues(alpha: 0.12);
      case NotificationType.chatNewMessage:
      default:
        return scheme.primaryContainer.withValues(alpha: 0.5);
    }
  }

  static Color _iconColorForType(NotificationType type, ColorScheme scheme) {
    switch (type) {
      case NotificationType.bookingAccepted:
      case NotificationType.bookingInvitationAccepted:
      case NotificationType.collaborationAccepted:
      case NotificationType.plannerNewEvent:
        return scheme.primary;
      case NotificationType.bookingDeclined:
      case NotificationType.bookingInvitationDeclined:
      case NotificationType.collaborationDeclined:
        return scheme.error;
      case NotificationType.chatNewMessage:
      default:
        return scheme.onPrimaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthRedirectNotifier>().user;
    if (user == null) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notifications)),
        body: Center(child: Text(l10n.signInToViewNotifications)),
      );
    }

    final role = user.role ?? UserRole.creativeProfessional;

    return BlocProvider(
      create: (_) => NotificationsCubit(
        sl(),
        user.id,
        role,
      ),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Text(
          l10n.notifications,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        scrolledUnderElevation: 1,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            buildWhen: (a, b) =>
                a.notifications != b.notifications ||
                a.readIds != b.readIds,
            builder: (context, state) {
              final hasUnread = state.notifications.any(
                (n) => !state.readIds.contains(n.id),
              );
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllAsRead(),
                child: Text(l10n.markAllRead),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (!state.hasLoaded && state.error == null) {
            return const NotificationListSkeleton();
          }

          final body = state.error != null
              ? const SizedBox.shrink()
              : CustomMaterialIndicator(
                  onRefresh: () async =>
                      context.read<NotificationsCubit>().load(),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  useMaterialContainer: false,
                  indicatorBuilder: (context, controller) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LoadingAnimationWidget.threeRotatingDots(
                      color: colorScheme.primary,
                      size: 40,
                    ),
                  ),
                  child: state.notifications.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight:
                                  MediaQuery.sizeOf(context).height - 200,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                child: EmptyStateIllustrated(
                                  assetPathDark: 'assets/images/notification_page_illustration_dark.svg',
                                  assetPathLight: 'assets/images/notification_page_illustration_light.svg',
                                  headline: l10n.noNotificationsYet,
                                  description: l10n.noNotificationsHint,
                                  primaryLabel: l10n.explore,
                                  onPrimaryPressed: () => context.go(AppRoutes.explore),
                                  illustrationHeight: 200,
                                ),
                              ),
                            ),
                          ),
                        )
                      : _NotificationList(
                          notifications: state.notifications,
                          readIds: state.readIds,
                          onTap: (n) => _onNotificationTap(context, n),
                        ),
                );

          return ConnectionErrorOverlay(
            hasError: state.error != null,
            error: state.error,
            onRefresh: () async {
              context.read<NotificationsCubit>().load();
            },
            onBack: () => context.go(AppRoutes.home),
            child: body,
          );
        },
      ),
      ),
    );
  }

  void _onNotificationTap(BuildContext context, NotificationEntity n) {
    context.read<NotificationsCubit>().markAsRead(n.id);
    if (n.routeExtra != null) {
      context.push(n.route, extra: n.routeExtra);
    } else {
      context.push(n.route);
    }
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.notifications,
    required this.readIds,
    required this.onTap,
  });

  final List<NotificationEntity> notifications;
  final Set<String> readIds;
  final void Function(NotificationEntity) onTap;

  @override
  Widget build(BuildContext context) {
    final sections = <String, List<NotificationEntity>>{};
    for (final n in notifications) {
      sections.putIfAbsent(
        NotificationsPage._sectionFor(context, n.createdAt),
        () => [],
      ).add(n);
    }
    final l10n = AppLocalizations.of(context)!;
    final order = [l10n.today, l10n.yesterday, l10n.thisWeek, l10n.older];
    final orderedSections = order
        .where((s) => sections.containsKey(s))
        .map((s) => MapEntry(s, sections[s]!))
        .toList();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: orderedSections.fold<int>(
        0,
        (sum, e) => sum + 1 + e.value.length,
      ),
      itemBuilder: (context, index) {
        var i = 0;
        for (final entry in orderedSections) {
          if (index == i) {
            final theme = Theme.of(context);
            return SectionHeader(
              title: entry.key,
              padding: const EdgeInsets.only(top: 16, bottom: 10),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            );
          }
          i++;
          for (final n in entry.value) {
            if (index == i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NotificationCard(
                  notification: n,
                  isRead: readIds.contains(n.id),
                  onTap: () => onTap(n),
                ),
              );
            }
            i++;
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  final NotificationEntity notification;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = NotificationsPage._iconForType(notification.type);
    final timeStr = NotificationsPage._formatTime(context, notification.createdAt);
    final iconBg = NotificationsPage._tintForType(notification.type, colorScheme)!;
    final iconColor =
        NotificationsPage._iconColorForType(notification.type, colorScheme);

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: onTap,
        child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  if (!isRead)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    AppIcons.chevronRight,
                    size: 20,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
        ),
      ),
    );
  }
}
