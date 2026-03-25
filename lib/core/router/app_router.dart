import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:go_router/go_router.dart';

import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/utils/toast_utils.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import '../../domain/entities/collaboration_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/verify_email_page.dart';
import '../../presentation/pages/activity_tab_page.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/messages_page.dart';
import '../../presentation/pages/settings_page.dart';
import '../../presentation/pages/profile/view_profile_page.dart';
import '../../presentation/pages/profile/creative_profile_edit_page.dart';
import '../../presentation/pages/profile/planner_profile_edit_page.dart';
import '../../presentation/pages/profile/profile_reviews_page.dart';
import '../../presentation/pages/profile/profile_portfolio_page.dart';
import '../../presentation/pages/profile/creative_past_work_page.dart';
import '../../presentation/pages/settings/change_username_page.dart';
import '../../presentation/pages/settings/change_email_page.dart';
import '../../presentation/pages/settings/privacy_settings_page.dart';
import '../../presentation/pages/onboarding/profile_setup_flow_page.dart';
import '../../presentation/pages/role_selection_page.dart';
import '../../presentation/pages/explore_page.dart';
import '../../presentation/pages/chat_page.dart';
import '../../presentation/pages/collaboration/collaboration_detail_page.dart';
import '../../presentation/pages/collaboration/send_collaboration_page.dart';
import '../../presentation/pages/create_event_page.dart';
import '../../presentation/pages/event_applicants_page.dart';
import '../../presentation/pages/event_detail_page.dart';
import '../../presentation/pages/following_page.dart';
import '../../presentation/pages/notifications_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/widgets/organisms/bottom_nav_shell.dart';

/// App route names.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String verifyEmail = '/verify-email';
  static const String roleSelection = '/role-selection';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String explore = '/explore';
  static const String exploreCreativesAll = '/explore/creatives';
  static const String messages = '/messages';
  static const String bookings = '/bookings';
  static const String profile = '/profile';
  static const String changeUsername = '/profile/change-username';
  static const String changeEmail = '/profile/change-email';
  static const String privacy = '/profile/privacy';
  static const String viewProfile = '/profile/view';
  static const String creativeProfile = '/profile/creative-profile';
  static const String plannerProfile = '/profile/planner-profile';
  static const String profileReviews = '/profile/view/reviews';
  static const String profilePortfolio = '/profile/view/portfolio';
  static const String profilePastWork = '/profile/view/past-work';

  /// Past work when viewing another creative (under /view/creative/:userId).
  static String creativePastWork(String userId) =>
      '/view/creative/$userId/past-work';
  static const String myEvents = '/my-events';
  static const String createEvent = '/bookings/create-event';

  /// Standalone edit event (outside shell). Must be top-level so extra (event)
  /// is preserved; shell child routes can lose extra.
  static const String editEvent = '/edit-event';

  /// Path for viewing event detail.
  static String eventDetail(String eventId) => '/event/$eventId';

  /// Path for viewing applicants (pending bookings) for an event (planner).
  static String eventApplicants(String eventId) => '/event/$eventId/applicants';

  /// Path for viewing another creative's public profile (top-level, no shell).
  static String creativeProfileView(String userId) => '/view/creative/$userId';

  /// Path for viewing another planner's public profile (top-level, no shell).
  static String plannerProfileView(String userId) => '/view/planner/$userId';

  /// Path for opening a chat thread by chat room id (from messages list).
  static String chat(String chatId) => '/messages/chat/$chatId';

  /// Path for opening or creating a 1:1 chat with another user (from profile).
  static String chatWithUser(String userId) => '/messages/with/$userId';

  /// Path for sending a collaboration proposal to a creative.
  static String sendCollaboration(String targetUserId) =>
      '/collaborate/$targetUserId';

  static const String collaborationDetail = '/collaboration/detail';

  static const String notifications = '/notifications';

  /// Path for creatives to view planners they follow.
  static const String following = '/following';
}

/// Application router configuration.
class AppRouter {
  AppRouter._();

  static GoRouter? _router;

  /// Lazily builds the router so tests can reset [sl] and call
  /// [resetRouterForTest] before first use in a test isolate.
  static GoRouter get router => _router ??= _createRouter();

  /// Clears the cached [GoRouter] so the next [router] access rebuilds with
  /// current service-locator registrations. For tests only.
  @visibleForTesting
  static void resetRouterForTest() {
    _router?.dispose();
    _router = null;
  }

  static GoRouter _createRouter() {
    final authNotifier = sl<AuthRedirectNotifier>();
    final splashNotifier = sl<SplashNotifier>();
    return GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      refreshListenable: Listenable.merge([authNotifier, splashNotifier]),
      redirect: (context, state) {
        // Firebase email link auth URLs open the app via App Links; handle them
        // as auth completion, not navigation. Redirect to splash so auth flow runs.
        final loc = state.uri.toString();
        if (loc.contains('__/auth') || loc.contains('finishSignIn')) {
          return AppRoutes.splash;
        }
        final isAuthenticated = authNotifier.isAuthenticated;
        final isAuthRoute =
            state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.verifyEmail;
        final isProfileSetupRoute =
            state.matchedLocation == AppRoutes.profileSetup;
        final isAppRoute =
            state.matchedLocation == AppRoutes.home ||
            state.matchedLocation == AppRoutes.explore ||
            state.matchedLocation.startsWith('/explore') ||
            state.matchedLocation == AppRoutes.messages ||
            state.matchedLocation.startsWith('/messages/') ||
            state.matchedLocation == AppRoutes.bookings ||
            state.matchedLocation.startsWith('/bookings') ||
            state.matchedLocation.startsWith('/event/') ||
            state.matchedLocation == AppRoutes.editEvent ||
            state.matchedLocation == AppRoutes.myEvents ||
            state.matchedLocation.startsWith(AppRoutes.profile) ||
            state.matchedLocation.startsWith('/view/') ||
            state.matchedLocation.startsWith('/collaborate/') ||
            state.matchedLocation.startsWith('/collaboration/') ||
            state.matchedLocation == AppRoutes.notifications ||
            state.matchedLocation == AppRoutes.following;

        // On iOS, use the same flow as Android: no onboarding intro, role selection, or
        // profile setup — go straight to login or home so both platforms show the same screens.
        final bool alignWithAndroid =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

        if (state.matchedLocation == AppRoutes.splash) {
          if (!splashNotifier.isComplete) return null;
          if (!isAuthenticated) return AppRoutes.login;
          if (!authNotifier.isReady) return null;
          if (authNotifier.needsEmailVerification) {
            return AppRoutes.verifyEmail;
          }
          if (!alignWithAndroid && authNotifier.needsRoleSelection) {
            return AppRoutes.roleSelection;
          }
          if (!alignWithAndroid && authNotifier.needsProfileSetup) {
            return AppRoutes.profileSetup;
          }
          if (!alignWithAndroid && authNotifier.user == null) {
            return AppRoutes.roleSelection;
          }
          return AppRoutes.home;
        }
        if (state.matchedLocation == '/register' ||
            state.matchedLocation == '/password-reset') {
          return AppRoutes.login;
        }
        if (!isAuthenticated && !isAuthRoute) {
          return AppRoutes.login;
        }
        if (isAuthenticated &&
            authNotifier.needsEmailVerification &&
            state.matchedLocation != AppRoutes.verifyEmail) {
          return AppRoutes.verifyEmail;
        }
        if (isAuthenticated && authNotifier.isReady) {
          if (!alignWithAndroid &&
              authNotifier.needsRoleSelection &&
              !state.matchedLocation.contains('role-selection')) {
            return AppRoutes.roleSelection;
          }
          if (!alignWithAndroid &&
              authNotifier.needsProfileSetup &&
              !isProfileSetupRoute &&
              state.matchedLocation != AppRoutes.roleSelection) {
            return AppRoutes.profileSetup;
          }
          if (!alignWithAndroid &&
              isAppRoute &&
              (authNotifier.needsRoleSelection ||
                  authNotifier.needsProfileSetup)) {
            if (authNotifier.needsRoleSelection) {
              return AppRoutes.roleSelection;
            }
            return AppRoutes.profileSetup;
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.createEvent,
          name: 'createEvent',
          builder: (context, state) {
            final creativeId = state.uri.queryParameters['creativeId'] ?? '';
            return CreateEventPage(invitedCreativeId: creativeId);
          },
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              BottomNavShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  name: 'home',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: HomePage()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/explore',
                  name: 'explore',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: ExplorePage()),
                  routes: [
                    GoRoute(
                      path: 'creatives',
                      name: 'exploreCreativesAll',
                      builder: (context, state) {
                        final extra = state.extra as Map<String, dynamic>?;
                        return ExploreCreativesAllPage(
                          category: extra?['category'] as ProfileCategory?,
                          location: extra?['location'] as String?,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/messages',
                  name: 'messages',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: MessagesPage()),
                  routes: [
                    GoRoute(
                      path: 'chat/:chatId',
                      name: 'chat',
                      builder: (context, state) {
                        final chatId = state.pathParameters['chatId'] ?? '';
                        if (chatId.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              showToast(
                                context,
                                'Chat not found',
                                isError: true,
                              );
                              context.go(AppRoutes.messages);
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
                        return ChatPage(chatId: chatId);
                      },
                    ),
                    GoRoute(
                      path: 'with/:userId',
                      name: 'chatWithUser',
                      builder: (context, state) {
                        final userId = state.pathParameters['userId'] ?? '';
                        if (userId.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              showToast(
                                context,
                                'User not found',
                                isError: true,
                              );
                              context.go(AppRoutes.messages);
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
                        return ChatPage(otherUserId: userId);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/bookings',
                  name: 'bookings',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: ActivityTabPage()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  name: 'profile',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: SettingsPage()),
                  routes: [
                    GoRoute(
                      path: 'change-username',
                      name: 'changeUsername',
                      pageBuilder: (context, state) => MaterialPage(
                        key: state.pageKey,
                        child: const ChangeUsernamePage(),
                      ),
                    ),
                    GoRoute(
                      path: 'change-email',
                      name: 'changeEmail',
                      pageBuilder: (context, state) => MaterialPage(
                        key: state.pageKey,
                        child: const ChangeEmailPage(),
                      ),
                    ),
                    GoRoute(
                      path: 'privacy',
                      name: 'privacy',
                      pageBuilder: (context, state) => MaterialPage(
                        key: state.pageKey,
                        child: const PrivacySettingsPage(),
                      ),
                    ),
                    GoRoute(
                      path: 'view',
                      name: 'viewProfile',
                      pageBuilder: (context, state) => MaterialPage(
                        key: state.pageKey,
                        child: const ViewProfilePage(),
                      ),
                      routes: [
                        GoRoute(
                          path: 'reviews',
                          name: 'profileReviews',
                          pageBuilder: (context, state) {
                            final userId =
                                state.uri.queryParameters['userId'] ?? '';
                            return MaterialPage(
                              key: state.pageKey,
                              child: ProfileReviewsPage(revieweeUserId: userId),
                            );
                          },
                        ),
                        GoRoute(
                          path: 'portfolio',
                          name: 'profilePortfolio',
                          pageBuilder: (context, state) {
                            final userId =
                                state.uri.queryParameters['userId'] ?? '';
                            return MaterialPage(
                              key: state.pageKey,
                              child: ProfilePortfolioPage(userId: userId),
                            );
                          },
                        ),
                        GoRoute(
                          path: 'past-work',
                          name: 'profilePastWork',
                          pageBuilder: (context, state) {
                            final userId =
                                state.uri.queryParameters['userId'] ?? '';
                            return MaterialPage(
                              key: state.pageKey,
                              child: CreativePastWorkPage(userId: userId),
                            );
                          },
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'creative-profile',
                      name: 'creativeProfile',
                      pageBuilder: (context, state) => MaterialPage(
                        key: state.pageKey,
                        child: const CreativeProfileEditPage(),
                      ),
                    ),
                    GoRoute(
                      path: 'planner-profile',
                      name: 'plannerProfile',
                      pageBuilder: (context, state) => MaterialPage(
                        key: state.pageKey,
                        child: const PlannerProfileEditPage(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) {
            final mode = state.uri.queryParameters['mode'];
            final showEmail = mode == 'email';
            return LoginPage(initialShowEmailForm: showEmail);
          },
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          name: 'verifyEmail',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            return VerifyEmailPage(email: email);
          },
        ),
        GoRoute(
          path: '/event/:eventId',
          name: 'eventDetail',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            if (eventId.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  showToast(context, 'Event not found', isError: true);
                  context.go(AppRoutes.home);
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
            return EventDetailPage(eventId: eventId);
          },
          routes: [
            GoRoute(
              path: 'applicants',
              name: 'eventApplicants',
              builder: (context, state) {
                final eventId = state.pathParameters['eventId'] ?? '';
                if (eventId.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      showToast(context, 'Event not found', isError: true);
                      context.go(AppRoutes.home);
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
                return EventApplicantsPage(eventId: eventId);
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.editEvent,
          name: 'editEvent',
          builder: (context, state) {
            final event = state.extra;
            return CreateEventPage(event: event is EventEntity ? event : null);
          },
        ),
        GoRoute(
          path: '/view/creative/:userId',
          name: 'creativeProfileView',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            if (userId.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  showToast(context, 'Profile not found', isError: true);
                  context.go(AppRoutes.profile);
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
            return ViewProfilePage(profileUserId: userId);
          },
          routes: [
            GoRoute(
              path: 'past-work',
              name: 'creativePastWork',
              builder: (context, state) {
                final userId = state.pathParameters['userId'] ?? '';
                if (userId.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      showToast(context, 'Profile not found', isError: true);
                      context.go(AppRoutes.profile);
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
                return CreativePastWorkPage(userId: userId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/collaboration/detail',
          name: 'collaborationDetail',
          builder: (context, state) {
            final args = state.extra;
            CollaborationEntity? collaboration;
            String? otherPersonName;
            String? otherPersonId;
            String? otherPersonPhotoUrl;
            UserRole? otherPersonRole;
            bool? viewerIsCreative;
            if (args is Map<String, dynamic>) {
              try {
                collaboration = args['collaboration'] as CollaborationEntity?;
                otherPersonName = args['otherPersonName'] as String?;
                otherPersonId = args['otherPersonId'] as String?;
                otherPersonPhotoUrl = args['otherPersonPhotoUrl'] as String?;
                otherPersonRole = args['otherPersonRole'] as UserRole?;
                viewerIsCreative = args['viewerIsCreative'] as bool?;
              } catch (_) {
                // Type cast failed
              }
            }
            if (collaboration == null ||
                otherPersonName == null ||
                otherPersonId == null ||
                viewerIsCreative == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  showToast(context, 'Invalid navigation', isError: true);
                  context.go(AppRoutes.profile);
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
            return CollaborationDetailPage(
              collaboration: collaboration,
              otherPersonName: otherPersonName,
              otherPersonId: otherPersonId,
              otherPersonPhotoUrl: otherPersonPhotoUrl,
              otherPersonRole: otherPersonRole,
              viewerIsCreative: viewerIsCreative,
            );
          },
        ),
        GoRoute(
          path: '/collaborate/:targetUserId',
          name: 'sendCollaboration',
          builder: (context, state) {
            final targetUserId = state.pathParameters['targetUserId'] ?? '';
            if (targetUserId.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  showToast(context, 'Invalid user', isError: true);
                  context.go(AppRoutes.profile);
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
            return SendCollaborationPage(targetUserId: targetUserId);
          },
        ),
        GoRoute(
          path: AppRoutes.notifications,
          name: 'notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: AppRoutes.following,
          name: 'following',
          builder: (context, state) => const FollowingPage(),
        ),
        GoRoute(
          path: '/view/planner/:userId',
          name: 'plannerProfileView',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            if (userId.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  showToast(context, 'Profile not found', isError: true);
                  context.go(AppRoutes.profile);
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
            return ViewProfilePage(
              profileUserId: userId,
              profileRole: UserRole.eventPlanner,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.roleSelection,
          name: 'roleSelection',
          builder: (context, state) {
            final user =
                (state.extra as UserEntity?) ??
                authNotifier.user ??
                sl<AuthRepository>().currentUser;
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
            return RoleSelectionPage(user: user);
          },
        ),
        GoRoute(
          path: AppRoutes.profileSetup,
          name: 'profileSetup',
          builder: (context, state) {
            final user =
                (state.extra as UserEntity?) ??
                authNotifier.user ??
                sl<AuthRepository>().currentUser;
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
            return ProfileSetupFlowPage(user: user);
          },
        ),
      ],
    );
  }
}
