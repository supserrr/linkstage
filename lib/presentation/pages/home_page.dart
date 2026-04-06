import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/router/auth_redirect.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/collaboration_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/followed_planners_repository.dart';
import '../../domain/repositories/saved_creatives_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../bloc/creative_dashboard/creative_dashboard_cubit.dart';
import '../bloc/planner_dashboard/planner_dashboard_cubit.dart';
import '../bloc/unread_notifications/unread_notifications_cubit.dart';
import '../widgets/organisms/creative_dashboard_content.dart';
import '../widgets/organisms/planner_dashboard_content.dart';

/// Main home screen. Shows planner dashboard for event planners,
/// creative dashboard for creatives.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = sl<AuthRedirectNotifier>();
    return ListenableBuilder(
      listenable: authNotifier,
      builder: (context, _) => _HomeContent(authNotifier: authNotifier),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.authNotifier});

  final AuthRedirectNotifier authNotifier;

  @override
  Widget build(BuildContext context) {
    final user = authNotifier.user;
    final isAuthenticated = authNotifier.isAuthenticated;
    final isReady = authNotifier.isReady;

    // Auth data still loading (e.g. right after login, before Firestore user/role fetched)
    if (isAuthenticated && !isReady) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.stretchedDots(
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
        ),
      );
    }

    final isPlanner = user?.role == UserRole.eventPlanner;
    final isCreative = user?.role == UserRole.creativeProfessional;
    final displayName =
        user?.displayName ??
        user?.username ??
        user?.email.split('@').first ??
        '';

    if (isPlanner && user != null) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => UnreadNotificationsCubit(
              sl<NotificationRepository>(),
              user.id,
              UserRole.eventPlanner,
            ),
          ),
          BlocProvider(
            create: (_) => PlannerDashboardCubit(
              sl<EventRepository>(),
              sl<BookingRepository>(),
              sl<UserRepository>(),
              sl<SharedPreferences>(),
              user.id,
            ),
          ),
        ],
        child: Scaffold(
          body: SafeArea(
            child: PlannerDashboardContent(displayName: displayName),
          ),
        ),
      );
    }

    if (isCreative && user != null) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => UnreadNotificationsCubit(
              sl<NotificationRepository>(),
              user.id,
              UserRole.creativeProfessional,
            ),
          ),
          BlocProvider(
            create: (_) => CreativeDashboardCubit(
              sl<ProfileRepository>(),
              sl<EventRepository>(),
              sl<BookingRepository>(),
              sl<CollaborationRepository>(),
              sl<SavedCreativesRepository>(),
              sl<FollowedPlannersRepository>(),
              sl<SharedPreferences>(),
              user.id,
            ),
          ),
        ],
        child: Scaffold(
          body: SafeArea(
            child: CreativeDashboardContent(displayName: displayName),
          ),
        ),
      );
    }

    // Should not reach here for authenticated users with complete profiles.
    // Router redirects to role selection or profile setup before home.
    // Redirect to the appropriate onboarding step instead of showing placeholder.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        if (authNotifier.needsRoleSelection || authNotifier.user == null) {
          context.go(AppRoutes.roleSelection, extra: authNotifier.user);
        } else if (authNotifier.needsProfileSetup) {
          context.go(AppRoutes.profileSetup, extra: authNotifier.user);
        }
      }
    });
    return Scaffold(
      body: Center(
        child: LoadingAnimationWidget.stretchedDots(
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
      ),
    );
  }
}
